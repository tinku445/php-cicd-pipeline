pipeline {
  agent none

  environment {
    BUILD_SERVER  = 'ec2-user@172.31.7.205'     // Build EC2 (private IP)
    DEPLOY_SERVER = 'ec2-user@172.31.4.188'     // Deploy EC2 (private IP)
    IMAGE_NAME    = "tinku187/php-app:${BUILD_NUMBER}"
  }

  stages {

    stage('Build Docker Image on Build Server') {
      agent any
      steps {
        sshagent(['slave2']) {

          // 1) Copy build context
          sh "scp -o StrictHostKeyChecking=no -r BuildConfig ${BUILD_SERVER}:/home/ec2-user/"

          // 2) Ensure Docker running on build host
          sh "ssh -o StrictHostKeyChecking=no ${BUILD_SERVER} 'bash /home/ec2-user/BuildConfig/docker-script.sh'"

          // 3) Build image
          sh "ssh -o StrictHostKeyChecking=no ${BUILD_SERVER} 'docker build -t ${IMAGE_NAME} /home/ec2-user/BuildConfig/'"

          // 4) Login & push (credentials expanded on Jenkins side, passed to remote as env)
          withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
            sh """
              ssh -o StrictHostKeyChecking=no ${BUILD_SERVER} "DOCKER_USER='${USER}'; DOCKER_PASS='${PASS}'; \
              echo \\$DOCKER_PASS | docker login -u \\$DOCKER_USER --password-stdin"
            """
            sh "ssh -o StrictHostKeyChecking=no ${BUILD_SERVER} 'docker push ${IMAGE_NAME}'"
          }
        }
      }
    }

    stage('Deploy with Docker Compose') {
      agent any
      steps {
        sshagent(['slave2']) {

          // 1) Copy deploy config
          sh "scp -o StrictHostKeyChecking=no -r DeployConfig ${DEPLOY_SERVER}:/home/ec2-user/"

          // 2) Make script executable
          sh "ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} 'chmod +x /home/ec2-user/DeployConfig/docker-compose-script.sh'"

          // 3) Docker login on deploy host
          withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
            sh """
              ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} "DOCKER_USER='${USER}'; DOCKER_PASS='${PASS}'; \
              echo \\$DOCKER_PASS | docker login -u \\$DOCKER_USER --password-stdin"
            """
          }

          // 4) Run compose with the image tag from Stage 1
          sh "ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} 'bash /home/ec2-user/DeployConfig/docker-compose-script.sh ${IMAGE_NAME}'"
        }
      }
    }
  }
}
