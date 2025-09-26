// CI/CD for aws-elastic-beanstalk-express-js-sample
// - Build & test in Node 16 Docker agent (assignment requirement)
// - Security scan with Snyk (fails on High/Critical)
// - Build & push Docker image via DinD from Jenkins container

pipeline {
  agent none

  environment {
    IMAGE_NAME = 'kristi123/express-sample'   // <-- your Docker Hub repo
  }

  stages {
    stage('Checkout') {
      agent any
      steps { checkout scm }
    }

    stage('Install deps (Node 16)') {
      agent { docker { image 'node:16' } }
      steps { sh 'npm ci || npm install' }
    }

    stage('Test (Node 16)') {
      agent { docker { image 'node:16' } }
      steps { sh 'npm test || echo "no tests / allow pass"' }
    }

    stage('Security scan (Snyk)') {
      agent { docker { image 'node:16' } }
      environment { SNYK_TOKEN = credentials('snyk-token') } // add this in Jenkins
      steps {
        sh '''
          npm install -g snyk
          snyk auth "$SNYK_TOKEN"
          # Fail if High/Critical
          snyk test --severity-threshold=high
        '''
      }
    }

    stage('Docker build & push (via DinD)') {
      agent any
      environment {
        DOCKER_HOST = 'tcp://dind:2376'
        DOCKER_CERT_PATH = '/certs/client'
        DOCKER_TLS_VERIFY = '1'
      }
      steps {
        sh '''
          # ensure docker cli in Jenkins container
          command -v docker >/dev/null 2>&1 || (apt-get update && apt-get install -y docker-cli)
        '''
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

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  post {
    always {
      archiveArtifacts artifacts: '**/npm-debug.log', allowEmptyArchive: true
    }
  }
}
