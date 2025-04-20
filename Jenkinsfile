pipeline {
    agent any
    tools {
        nodejs 'nodejs-23-11-0'
    }
    stages {
        stage('Test Connection') {
            steps {
                echo "🎉 Jenkins is connected to GitHub Organization!"
            }
        }
         stage('Check Nodejs Version') {
            steps {
                sh '''
                   node -v
                   npm -v
                '''
            }
        }
    }
}
