pipeline {
    agent any
    tools {
        nodejs 'nodejs-23-11-0'
    }
    environment {
        SONAR_SCANNER_HOME = tool 'sonarqube-scanner-710'
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
                        --disableYarnAudit \
                        --prettyPrint''', odcInstallation: 'OWASP-DepCheck-12'

                        dependencyCheckPublisher failedTotalCritical: 1, pattern: 'dependency-check-report.xml', stopBuild: true
                        publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: './', reportFiles: 'dependency-check-jenkins.html', reportName: 'Dependency Check HTML Report', reportTitles: '', useWrapperFileDirectly: true])
                        junit allowEmptyResults: true, keepProperties: true, testResults: 'dependency-check-junit.xml'
                    }
                }
            }
        }
        stage('SAST - SonarQube') {
            steps {
                timeout(time: 60, unit: 'SECONDS') {
                    withSonarQubeEnv('sonar-qube-server') {
                    sh '''
                       $SONAR_SCANNER_HOME/bin/sonar-scanner \
                          -Dsonar.projectKey=frontend-project \
                          -Dsonar.sources=./src 
                    '''
                    }
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }
}
