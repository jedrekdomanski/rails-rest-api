pipeline {
  agent { label 'agent1' }
  stages {
    stage('verify tooling') {
      steps {
        sh '''
          docker info
          docker version
          docker compose version
          curl --version
          jq --version
        '''
      }
    }
    stage('Test') {
      steps {
        sh 'docker-compose run web bundle exec rspec'
      }
    }
  }
}
