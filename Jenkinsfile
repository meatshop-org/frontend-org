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
                           echo eladwy
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
                        publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: './', reportFiles: 'dependency-check-jenkins.html', reportName: 'Dependency Check HTML Report', reportTitles: '', useWrapperFileDirectly: true])
                        junit allowEmptyResults: true, keepProperties: true, testResults: 'dependency-check-junit.xml'
                    }
                }
            }
        }
    }
}
