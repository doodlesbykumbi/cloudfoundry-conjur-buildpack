package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/cyberark/conjur-api-go/conjurapi"
	"github.com/cyberark/summon/secretsyml"
	"github.com/hashicorp/go-retryablehttp"
	"golang.org/x/time/rate"
)

type Provider interface {
	RetrieveSecret(string) ([]byte, error)
}

type CatProvider struct {
}

func (CatProvider) RetrieveSecret(path string) ([]byte, error) {
	return ioutil.ReadFile(path)
}

type VcapServices struct {
	ConjurInfo ConjurInfo
}

type ConjurInfo struct {
	Credentials ConjurCredentials `json:"credentials"`
}

type ConjurCredentials struct {
	ApplianceURL   string `json:"appliance_url"`
	APIKey         string `json:"authn_api_key"`
	Login          string `json:"authn_login"`
	Account        string `json:"account"`
	SSLCertificate string `json:"ssl_certificate"`
	Version        int    `json:"version"`
}

func (ci ConjurInfo) setEnv() {
	ci.Credentials.setEnv()
}

func (c ConjurCredentials) setEnv() {
	os.Setenv("CONJUR_APPLIANCE_URL", c.ApplianceURL)
	os.Setenv("CONJUR_AUTHN_LOGIN", c.Login)
	os.Setenv("CONJUR_AUTHN_API_KEY", c.APIKey)
	os.Setenv("CONJUR_ACCOUNT", c.Account)
	os.Setenv("CONJUR_SSL_CERTIFICATE", c.SSLCertificate)
	os.Setenv("CONJUR_VERSION", strconv.Itoa(c.Version))
}

const SERVICE_LABEL = "cyberark-conjur"

func setConjurCredentialsEnv() error {
	// Get the Conjur connection information from the VCAP_SERVICES
	VCAP_SERVICES := os.Getenv("VCAP_SERVICES")

	if VCAP_SERVICES == "" {
		return fmt.Errorf("VCAP_SERVICES environment variable is empty or doesn't exist\n")
	}

	services := VcapServices{}
	err := json.Unmarshal([]byte(VCAP_SERVICES), &services)
	if err != nil {
		return fmt.Errorf("Error parsing Conjur connection information: %v\n", err.Error())
	}

	conjurInfo := services.ConjurInfo
	conjurInfo.setEnv()

	return nil
}

// RoundTripper allows us to convert a function into a http.RoundTripper
type RoundTripper func(*http.Request) (*http.Response, error)
func (r RoundTripper) RoundTrip(req *http.Request) (*http.Response, error) {
	return r(req)
}

// WrappedRetriableHTTPClient wraps a retryablehttp.Client so that it can be consumed as
// an http.Client.
func WrappedRetriableHTTPClient(retriableClient *retryablehttp.Client) *http.Client {
	return &http.Client{
		Transport: RoundTripper(
			func(req *http.Request) (*http.Response, error) {
				retriableRequest, err := retryablehttp.FromRequest(req)

				if err != nil {
					return nil, err
				}

				return retriableClient.Do(retriableRequest)
			},
		),
	}
}

func NewProvider() (Provider, error) {
	//return CatProvider{}, nil
	err := setConjurCredentialsEnv()
	if err != nil {
		return nil, err
	}

	config, err := conjurapi.LoadConfig()
	if err != nil {
		return nil, err
	}

	client, err := conjurapi.NewClientFromEnvironment(config)
	if err != nil {
		return nil, err
	}

	retriableClient := &retryablehttp.Client{
		HTTPClient: client.GetHttpClient(),
		RetryWaitMax: 3 * time.Second,
		Backoff:      retryablehttp.LinearJitterBackoff,
		CheckRetry:   retryablehttp.DefaultRetryPolicy,
		RetryMax:     3,
	}

	client.SetHttpClient(WrappedRetriableHTTPClient(retriableClient))

	return client, nil
}

// workCoordinator is a structure that bundles the following capabilities:
// 1. limiting concurrency
// 2. request rate limiting
// 3. waiting for the completion of work
type workCoordinator struct {
	// wg ensures the completion of all started requests
	wg sync.WaitGroup
	// limiter maintains the request rate
	limiter *rate.Limiter
	// sem maintains the concurrency limit
	sem chan bool

	maxConcurrency int
	maxWorkRate    int
}

func newWorkCoordinator(
	maxConcurrency int,
	maxRequestRate int,
) *workCoordinator {
	var limiter *rate.Limiter
	var sem chan bool

	if maxConcurrency > 0 {
		limiter = rate.NewLimiter(rate.Every(time.Second/time.Duration(maxConcurrency)), 1)
	}

	if maxRequestRate > 0 {
		sem = make(chan bool, maxConcurrency)
	}

	return &workCoordinator{
		wg:             sync.WaitGroup{},
		limiter:        limiter,
		sem:            sem,
	}
}

func (l *workCoordinator) Add() {
	if l.limiter != nil {
		err := l.limiter.Wait(context.Background())
		if err != nil {
			panic(err)
		}
	}

	if l.sem != nil {
		l.sem <- true
	}

	l.wg.Add(1)
}

func (l *workCoordinator) Done() {
	if l.sem != nil {
		<-l.sem
	}

	l.wg.Done()
}

func (l *workCoordinator) Wait() {
	l.wg.Wait()
}

const defaultMaxConcurrency=10
const defaultRequestRate=-1

func main() {
	var (
		provider Provider
		err      error
		secrets  secretsyml.SecretsMap
	)

	maxConcurrencyStr, exists := os.LookupEnv("SECRETS_MAX_CONCURRENCY")
	var maxConcurrency = defaultMaxConcurrency
	if exists {
		maxConcurrency, err = strconv.Atoi(maxConcurrencyStr)
		if err != nil {
			finalErr := fmt.Errorf(
				"unable to convert environment variable 'SECRETS_MAX_CONCURRENCY' to integer: %s\n",
				err,
			)
			printAndExitIfError(finalErr)
		}
	}

	maxRequestRateStr, exists := os.LookupEnv("SECRETS_MAX_REQUEST_RATE")
	var maxRequestRate = defaultRequestRate
	if exists {
		maxRequestRate, err = strconv.Atoi(maxRequestRateStr)
		if err != nil {
			finalErr := fmt.Errorf(
				"unable to convert environment variable 'SECRETS_MAX_REQUEST_RATE' to integer: %s\n",
				err,
			)
			printAndExitIfError(finalErr)
		}
	}

	secretsYamlPath, exists := os.LookupEnv("SECRETS_YAML_PATH")
	if !exists {
		secretsYamlPath = "secrets.yml"
	}

	secrets, err = secretsyml.ParseFromFile(secretsYamlPath, "", nil)
	if os.IsNotExist(err) {
		printAndExitIfError(fmt.Errorf("%s not found\n", secretsYamlPath))
	}
	printAndExitIfError(err)

	tempFactory := NewTempFactory("")
	// defer tempFactory.Cleanup()
	// no need to cleanup because we're injecting values to the environment

	type Result struct {
		key   string
		bytes []byte
		error
	}

	// Lazy loading provider
	for _, spec := range secrets {
		if provider == nil && spec.IsVar() {
			provider, err = NewProvider()
			printAndExitIfError(err)
		}
	}

	// Channel for collecting results from concurrent request
	results := make(chan Result, len(secrets))

	workCoordinator := newWorkCoordinator(maxConcurrency, maxRequestRate)
	for key, spec := range secrets {
		// Add work
		workCoordinator.Add()

		go func(key string, spec secretsyml.SecretSpec) {
			var (
				secretBytes []byte
				err         error
			)

			if spec.IsVar() {
				secretBytes, err = provider.RetrieveSecret(spec.Path)

				if spec.IsFile() {
					fname := tempFactory.Push(secretBytes)
					secretBytes = []byte(fname)
				}
			} else {
				// If the spec isn't a variable, use its value as-is
				secretBytes = []byte(spec.Path)
			}

			results <- Result{key, secretBytes, err}

			// Mark work as done
			workCoordinator.Done()
			return
		}(key, spec)
	}

	// Wait for all the concurrent work to be done
	workCoordinator.Wait()

	close(results)

	var exportStrings []string

	for result := range results {
		if result.error == nil {
			exportString := fmt.Sprintf("export %s='%s';", result.key, strings.Replace(string(result.bytes), "'", "'\"'\"'", -1))
			exportStrings = append(exportStrings, exportString)
		} else {
			printAndExitIfError(fmt.Errorf("error fetching variable - %s", result.error))
		}
	}

	fmt.Print(strings.Join(exportStrings, "\n"))
}

func printAndExitIfError(err error) {
	if err == nil {
		return
	}
	os.Stderr.Write([]byte(err.Error()))
	os.Exit(1)
}

// UnmarshalJSON implements the json.Unmarshaler interface for VcapServices,
// which allows us to only unmarshal the `cyberark-conjur` service object
// using the ConjurInfo struct.
func (vcapServices *VcapServices) UnmarshalJSON(b []byte) error {
	services := make(map[string][]interface{})
	err := json.Unmarshal(b, &services)
	if err != nil {
		return err
	}

	conjurServices, ok := services[SERVICE_LABEL]
	if !ok || len(conjurServices) == 0 {
		return errors.New("no Conjur services are bound to this application")
	}

	infoBytes, err := json.Marshal(conjurServices[0])
	if err != nil {
		return err
	}

	info := ConjurInfo{}
	err = json.Unmarshal(infoBytes, &info)
	if err != nil {
		return err
	}

	vcapServices.ConjurInfo = info
	return nil
}
