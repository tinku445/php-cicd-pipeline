pipeline {
    agent none

    environment {
        BUILD_SERVER = 'ec2-user@172.31.7.205'
        DEPLOY_SERVER = 'ec2-user@172.31.4.188'
        IMAGE_NAME = "tinku187/php-app:${BUILD_NUMBER}"
    }

    stages {

        stage('Build Docker Image on Build Server') {
            agent any
            steps {
                sshagent(['slave2']) {
                    // Copy Build files to Build Server
                    sh "scp -o StrictHostKeyChecking=no -r BuildConfig ${BUILD_SERVER}:/home/ec2-user/"

                    // Prepare build server (install docker if needed)
                    sh "ssh -o StrictHostKeyChecking=no ${BUILD_SERVER} 'bash /home/ec2-user/BuildConfig/docker-script.sh'"

                    // Build docker image
                    sh "ssh -o StrictHostKeyChecking=no ${BUILD_SERVER} 'docker build -t ${IMAGE_NAME} /home/ec2-user/BuildConfig/'"

                    // Login & Push to DockerHub
                    withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                        sh "ssh ${BUILD_SERVER} 'echo $PASS | docker login -u $USER --password-stdin'"
                        sh "ssh ${BUILD_SERVER} 'docker push ${IMAGE_NAME}'"
                    }
                }
            }
        }

        stage('Deploy on Deploy Server with Docker Compose') {
            agent any
            steps {
                sshagent(['slave2']) {
                    // Copy deploy files
                    sh "scp -o StrictHostKeyChecking=no -r DeployConfig ${DEPLOY_SERVER}:/home/ec2-user/"

                    // Ensure permission
                    sh \"ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} 'chmod +x /home/ec2-user/DeployConfig/docker-compose-script.sh'\"

                    // Login to DockerHub on Deploy server
                    withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                        sh "ssh ${DEPLOY_SERVER} 'echo $PASS | docker login -u $USER --password-stdin'"
                    }

                    // Run compose deploy script
                    sh "ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} 'bash /home/ec2-user/DeployConfig/docker-compose-script.sh ${IMAGE_NAME}'"
                }
            }
        }
    }
}
