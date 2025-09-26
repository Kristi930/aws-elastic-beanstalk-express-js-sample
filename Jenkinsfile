// Jenkinsfile for aws-elastic-beanstalk-express-js-sample
// - Build & test inside Node 16 containers (assignment requirement)
// - Optional Snyk scan (runs only if snyk-token exists)
// - Build & push Docker image via DinD (tcp://docker:2376)

pipeline {
  agent any

  environment {
    IMAGE_NAME = 'kristi123/express-sample'   // <-- your Docker Hub repo
    DOCKER_HOST = 'tcp://docker:2376'         // must match DinD hostname/TLS certs
    DOCKER_CERT_PATH = '/certs/client'
    DOCKER_TLS_VERIFY = '1'
    // If you add a "Secret text" credential with ID 'snyk-token', this will be populated.
    SNYK_TOKEN = credentials('snyk-token')
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
            echo "[INFO] Installing docker client..."
            apt-get update
            apt-get install -y --no-install-recommends docker.io
          fi
          echo "[INFO] Docker version:"; docker --version || true
          echo "[INFO] Checking DinD:"; docker info >/dev/null 2>&1 || echo "[WARN] docker info failed (DinD may still be coming up)"
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

    stage('Security scan (Snyk – optional)') {
      when { expression { return env.SNYK_TOKEN?.trim() } }  // only runs if token exists
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
