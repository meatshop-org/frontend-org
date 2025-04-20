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
        stage('Dependency Scanning'){
            parallel {
                stage('Dependency Audit') {
                    steps {
                        sh '''
                           npm audit --audit-level=critical
                           echo $?
                        '''
                    }
                }
                stage('OWASP Dependency Check') {
                    steps {
                       dependencyCheck additionalArguments: '''
                        --scan	\'./\'
                        --out \'./\'
                        --format \'ALL\'
                        --prettyPrint''', odcInstallation: 'OWASP-DepCheck-12'

                        dependencyCheckPublisher failedTotalCritical: 1, pattern: 'dependency-check-report.xml', stopBuild: true
                    }
                }
            }
        }
    }
}
