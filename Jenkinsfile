pipeline {
    agent any
    tools {
        nodejs 'nodejs-23-11-0'
    }
    stages {
        stage('Installing Dependencies') {
            steps {
                sh 'npm install --no-audit'
            }
        }
        stage('Dependency Audit') {
            steps {
                sh '''
                   npm audit --audit-level=critical
                   echo $?
                '''
            }
        }
    }
}
