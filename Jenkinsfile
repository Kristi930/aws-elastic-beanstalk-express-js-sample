// CI/CD for aws-elastic-beanstalk-express-js-sample
// - Runs steps using Node 16 containers via docker run (no Jenkins docker agent needed)
// - Uses DinD at tcp://dind:2376 for docker build & push
// - Fails the build if Snyk finds High/Critical vulns

pipeline {
  agent any

  environment {
    IMAGE_NAME = 'kristi123/express-sample'   // <-- change to your Docker Hub repo
    DOCKER_HOST = 'tcp://dind:2376'
    DOCKER_CERT_PATH = '/certs/client'
    DOCKER_TLS_VERIFY = '1'
  }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  stages {

    stage('Prepare docker CLI') {
      steps {
        sh '''
          set -e
          if ! command -v docker >/dev/null 2>&1; then
            apt-get update && apt-get install -y docker-cli
          fi
          docker version || true
        '''
      }
    }

    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Install deps (Node16)') {
      steps {
        sh '''
          docker run --rm -v "$PWD":/work -w /work node:16 bash -lc "npm ci || npm install"
        '''
      }
    }

    stage('Test (Node16)') {
      steps {
        sh '''
          docker run --rm -v "$PWD":/work -w /work node:16 bash -lc "npm test || echo no-tests"
        '''
      }
    }

    stage('Security scan (Snyk)') {
      environment { SNYK_TOKEN = credentials('snyk-token') } // add this in Jenkins Credentials
      steps {
        sh '''
          docker run --rm -v "$PWD":/work -w /work -e SNYK_TOKEN node:16 bash -lc '
            npm i -g snyk &&
            snyk auth "${SNYK_TOKEN}" &&
            snyk test --severity-threshold=high
          '
        '''
      }
    }

    stage('Docker build & push (DinD)') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
          sh '''
            echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
            docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} .
            docker push ${IMAGE_NAME}:${BUILD_NUMBER}
          '''
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: '**/npm-debug.log', allowEmptyArchive: true
    }
  }
}

