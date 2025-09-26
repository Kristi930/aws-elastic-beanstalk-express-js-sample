pipeline {
  agent { label 'built-in' }

  environment {
    IMAGE_NAME = "kristi123/express-sample"
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
          tar -C . -cf - . | docker run --rm -i -w /work node:16 bash -lc '
            mkdir -p /work
            tar -xf - -C /work
            if [ -f /work/package-lock.json ]; then npm ci; else npm install; fi
          '
        '''
      }
    }

    stage('Test (Node16)') {
      steps {
        sh '''
          set -e
          tar -C . -cf - . | docker run --rm -i -w /work node:16 bash -lc '
            mkdir -p /work
            tar -xf - -C /work
            if [ -f /work/package-lock.json ]; then npm ci; else npm install; fi
            npm test
          '
        '''
      }
    }

    stage('Security scan (Snyk)') {
      environment { SNYK_TOKEN = credentials('snyk-token') }
      steps {
        sh '''
          set -e
          tar -C . -cf - . | docker run --rm -i -e SNYK_TOKEN -w /work node:16 bash -lc '
            mkdir -p /work
            tar -xf - -C /work
            if [ -f /work/package-lock.json ]; then npm ci; else npm install; fi
            npx --yes snyk@latest test --severity-threshold=high
          '
        '''
      }
    }

    stage('Docker build & push (DinD)') {
      steps {
        withDockerRegistry([ credentialsId: 'docker-hub-creds', url: '' ]) {
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
      archiveArtifacts artifacts: '**/target/*.jar', allowEmptyArchive: true
      fingerprint '**/target/*.jar'
    }
  }
}

