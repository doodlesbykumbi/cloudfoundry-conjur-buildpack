FROM cloudfoundry/cflinuxfs2

ENV RUBY_PACKAGES bundler

# Update and install all of the required packages.
RUN gem install $RUBY_PACKAGES

# Install the Cloud Foundry CLI
RUN apt-get update -y && apt-get install -y apt-transport-https ca-certificates openssl
RUN wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | apt-key add - && \
    echo "deb https://packages.cloudfoundry.org/debian stable main" | tee /etc/apt/sources.list.d/cloudfoundry-cli.list && \
    apt-get update -y && \
    apt-get install -y cf-cli

ENV WD_PATH /conjurinc/cloudfoundry-conjur-buildpack
ENV CI_PATH $WD_PATH/ci
RUN mkdir -p $CI_PATH
WORKDIR $WD_PATH

COPY Gemfile $CI_PATH
RUN cd $CI_PATH && bundle install
