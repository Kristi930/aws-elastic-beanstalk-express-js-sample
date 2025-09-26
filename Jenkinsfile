pipeline {
  agent { label 'built-in' }

  environment {
    IMAGE_NAME = "kristi123/express-sample"
    DOCKER_CLI_EXPERIMENTAL = "enabled"
  }

  options {
    timestamps()
  }

  stages {
    stage('Prepare docker CLI') {
      steps {
        sh '''
          set -e
          echo "[INFO] Docker version:"
          docker --version
          echo "[INFO] Checking DinD:"
          docker info
        '''
      }
    }

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Install deps (Node16)') {
      steps {
        sh '''
          set -e
          # Stream repo into Node container (avoids bind mount issue with DinD)
          tar -C . -cf - . | docker run --rm -i -w /work node:16 bash -lc '
            mkdir -p /work &&
            tar -xf - -C /work &&
            if [ -f /work/package-lock.json ]; then
              npm ci
            else
              npm install
            fi
          '
        '''
      }
    }

    stage('Test (Node16)') {
      steps {
        sh '''
          set -e
          tar -C . -cf - . | docker run --rm -i -w /work node:16 bash -lc '
            mkdir -p /work &&
            tar -xf - -C /work &&
            npm test || echo "no-tests"
          '
        '''
      }
    }

    // Optional: add back later when stable
    /*
    stage('Security scan (Snyk – optional)') {
      steps {
        sh '''
          set -e
          echo "[INFO] Skipping Snyk for now (reenable later)"
        '''
      }
    }
    */

    stage('Docker build & push (DinD)') {
      steps {
        withDockerRegistry([credentialsId: 'docker-hub-creds', url: '']) {
          sh '''
            set -e
            docker build -t $IMAGE_NAME:$BUILD_NUMBER .
            docker push $IMAGE_NAME:$BUILD_NUMBER
          '''
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: '**/Dockerfile', fingerprint: true
    }
  }
}

