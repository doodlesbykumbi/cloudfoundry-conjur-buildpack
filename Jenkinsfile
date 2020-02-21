#!/usr/bin/env groovy

pipeline {
  agent { label 'executor-v2' }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '30'))
  }

  triggers {
    cron(getDailyCronString())
  }

  stages {
    stage('Validate') {
      parallel {
        stage('Changelog') {
          steps { sh './bin/parse-changelog.sh' }
        }
      }
    }
    
    stage('Build buildpack') {
      steps {
        sh './package.sh'

        archiveArtifacts artifacts: '*.zip', fingerprint: true
      }
    }
    stage('Test') {
      steps {
        sh 'summon ./test.sh'

        junit 'ci/features/reports/*.xml'
      }
    }

  }

  post {
    always {
      cleanupAndNotify(currentBuild.currentResult)
    }
  }
}
