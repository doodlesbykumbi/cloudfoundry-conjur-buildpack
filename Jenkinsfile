#!/usr/bin/env groovy

pipeline {
  agent { label 'executor-v2' }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '30'))
  }

  stages {
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
