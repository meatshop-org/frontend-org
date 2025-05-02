pipeline {
    agent any
    tools {
        nodejs 'nodejs-23-11-0'
    }
    environment {
        SONAR_SCANNER_HOME = tool 'sonarqube-scanner-710'
        GITHUB_TOKEN = credentials('github-pat')
        USER_EMAIL = credentials('github-email')
        FGGITHUB_TOKEN = credentials('FGgithub-pat')
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
                    }
                }
            }
        }
        stage('SAST - SonarQube') {
            steps {
                timeout(time: 120, unit: 'SECONDS') {
                    withSonarQubeEnv('sonar-qube-server') {
                        sh '''
                            $SONAR_SCANNER_HOME/bin/sonar-scanner \
                               -Dsonar.projectKey=frontend-project \
                               -Dsonar.sources=./src \
                         '''
                    }
                    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t borhom11/frontend-meatshop:$GIT_COMMIT .'
            }   
        }
        stage('Trivy Vulnarability Scanner'){
            steps {
                sh '''
                    trivy image borhom11/frontend-meatshop:$GIT_COMMIT \
                        --severity LOW,MEDIUM \
                        --exit-code 0 \
                        --quiet \
                        --format json -o trivy-image-MEDIUM-results.json
    
                     trivy image borhom11/frontend-meatshop:$GIT_COMMIT \
                        --severity HIGH,CRITICAL \
                        --exit-code 1 \
                        --quiet \
                        --format json -o trivy-image-CRITICAL-results.json
                '''
            }
            post {
                always {
                    sh '''
                        trivy convert \
                            --format template --template "@/usr/local/share/trivy/templates/html.tpl" \
                            --output trivy-image-MEDIUM-results.html trivy-image-MEDIUM-results.json
                            
                        trivy convert \
                            --format template --template "@/usr/local/share/trivy/templates/html.tpl" \
                            --output trivy-image-CRITICAL-results.html trivy-image-CRITICAL-results.json
                            
                        trivy convert \
                            --format template --template "@/usr/local/share/trivy/templates/junit.tpl" \
                            --output trivy-image-MEDIUM-results.xml trivy-image-MEDIUM-results.json
                            
                        trivy convert \
                            --format template --template "@/usr/local/share/trivy/templates/junit.tpl" \
                            --output trivy-image-CRITICAL-results.xml trivy-image-CRITICAL-results.json
                    '''
                }
            }
        }
        stage('Push Docker Image') {
            steps {
                withDockerRegistry(url: 'https://index.docker.io/v1/', credentialsId: 'docker-hub-creds') {
                    sh 'docker push borhom11/frontend-meatshop:$GIT_COMMIT'
                }
            }   
        }
        stage('Deploy - AWS EC2') {
            when {
                branch 'feature/*'
            }
            steps {
                script {
                    sshagent(['aws-dev-deploy-ec2-instance']) {
                        sh '''
                            ssh -o StrictHostKeyChecking=no ubuntu@157.175.219.194 "
                                if sudo docker ps -a | grep -q "frontend-meatshop"; then
                                    echo "Container Found, Stopping..."
                                    sudo docker stop "frontend-meatshop" && sudo docker rm "frontend-meatshop"
                                    echo "Container stopped and removed"
                                fi
                                sudo docker run --name frontend-meatshop -p 80:80 -d borhom11/frontend-meatshop:$GIT_COMMIT
                            "
                        '''
                    }
                }
            }   
        }

        stage('Integration Testing - AWS EC2') {
            when {
                branch "feature/*"
            }
            steps {
                withAWS(credentials: 'aws-s3-ec2-lambda-creds', region: 'me-south-1') {
                    sh '''
                        bash integration-testing-ec2.sh
                    '''
                }
            }
        }

        stage('K8S Update Image Tag') {
            when {
                branch 'PR*'
            }
            steps {
                sh 'git clone -b main https://github.com/BRHM1/k8s-meatshop.git'
                dir('k8s-meatshop/frontend') {
                    sh '''
                        git checkout main
                        git checkout -b feature-$BUILD_ID
                        sed -i "s|borhom11/frontend[^ ]*|borhom11/frontend-meatshop:$GIT_COMMIT|g" deployment.yaml

                        git config --global user.email $USER_EMAIL
                        git remote set-url origin https://$GITHUB_TOKEN@github.com/BRHM1/k8s-meatshop.git
                        git add . 
                        git commit -m "FROM CI/CD - Update image tag to $GIT_COMMIT"
                        git push origin feature-$BUILD_ID
                    '''
                }
            }
        }

        stage('K8S Raise PR Review') {
            when {
                branch 'PR*'
            }
            steps {
                sh '''
                    curl -L \
                        -X POST \
                        -H "Accept: application/vnd.github+json" \
                        -H "Authorization: Bearer $FGGITHUB_TOKEN" \
                        -H "X-GitHub-Api-Version: 2022-11-28" \
                        https://api.github.com/repos/BRHM1/k8s-meatshop/pulls \
                        -d '{"title":"Raised PR From CI/CD","body":"Please pull these awesome changes in!","head":"feature-'"$BUILD_ID"'","base":"main"}'
                '''
            }
        }

        stage('Simulating K8S Running Application') {
            when {
                branch 'PR*'
            }
            steps {
                sh '''
                    if docker ps -a | grep -q "frontend-meatshop"; then
                        echo "Container Found, Stopping..."
                        docker stop "frontend-meatshop" && docker rm "frontend-meatshop"
                        echo "Container stopped and removed"
                    fi
                    docker run --name frontend-meatshop -p 80:80 -d borhom11/frontend-meatshop:$GIT_COMMIT
                '''
            }
        }

        stage('PR merged & ArgoCD synced?') {
            when {
                branch 'PR*'
            }
            steps{
                timeout(time: 1, unit: 'DAYS') {
                    input message: 'Confirm that the manifest repo PR is merged and ArgoCD is synced.', ok: 'YES! All Done', submitter: 'admin'
                }
            }
        }

        stage('DAST - OWASP ZAP') {
            when {
                branch 'PR*'
            }
            steps {
                sh '''
                    echo "Trigger"
                    chmod 777 $(pwd)
                    docker run -v $(pwd):/zap/wrk/:rw -t ghcr.io/zaproxy/zaproxy:stable zap-full-scan.py \
                        -t http://192.168.127.131:80/ \
                        -r zap_report.html \
                        -w zap_report.md \
                        -x zap_report.xml \
                        -J zap_report.json \
                        -c zap_ignore_rules
                '''
            }
        }

        stage('Publish Reports - AWS S3') {
            when {
                branch 'PR*'
            }
            steps {
                withAWS(credentials: 'aws-s3-ec2-lambda-creds', region: 'me-south-1') {
                    sh '''
                        mkdir reports-$BUILD_ID
                        cp dependency*.* trivy*.* zap*.* reports-$BUILD_ID/
                        ls reports-$BUILD_ID/
                        echo Hello
                    '''
                    s3Upload(
                        file: "reports-$BUILD_ID",
                        bucket: "meatshop-pipeline-reports",
                        path: "frontend/reports-$BUILD_ID"
                    )
                }
            }
        }
        
    }
    post {
        always {
            script {
                if (fileExists('k8s-meatshop')) {
                    sh 'rm -rf k8s-meatshop'
                }
            }

            junit allowEmptyResults: true, keepProperties: true, testResults: 'dependency-check-junit.xml'

            junit allowEmptyResults: true, stdioRetention: '', testResults: 'trivy-image-MEDIUM-results.xml'
            junit allowEmptyResults: true, stdioRetention: '', testResults: 'trivy-image-CRITICAL-results.xml'

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: './', reportFiles: 'dependency-check-jenkins.html', reportName: 'Dependency Check HTML Report', reportTitles: '', useWrapperFileDirectly: true])
            
            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: './', reportFiles: 'trivy-image-MEDIUM-results.html', reportName: 'Trivy Image Medium vulnarability Report', reportTitles: '', useWrapperFileDirectly: true])
            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: './', reportFiles: 'trivy-image-CRITICAL-results.html', reportName: 'Trivy Image CRITICAL vulnarability Report', reportTitles: '', useWrapperFileDirectly: true])
            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: './', reportFiles: 'zap_report.html', reportName: 'DAST - OWASP ZAP Report', reportTitles: '', useWrapperFileDirectly: true])

        }
    }
}
