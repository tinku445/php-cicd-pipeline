pipeline {
  agent none

  environment {
    BUILD_SERVER  = 'ec2-user@172.31.7.205'
    DEPLOY_SERVER = 'ec2-user@172.31.4.188'
    IMAGE_NAME    = "tinku187/php-app:${BUILD_NUMBER}"
  }

  stages {

    stage('Build Docker Image on Build Server') {
      agent any
      steps {
        sshagent(['slave2']) {
          // copy build context
          sh "scp -o StrictHostKeyChecking=no -r BuildConfig ${BUILD_SERVER}:/home/ec2-user/"

          // prep build server (installs/starts docker if needed)
          sh "ssh -o StrictHostKeyChecking=no ${BUILD_SERVER} 'bash /home/ec2-user/BuildConfig/docker-script.sh'"

          // build image
          sh "ssh -o StrictHostKeyChecking=no ${BUILD_SERVER} 'docker build -t ${IMAGE_NAME} /home/ec2-user/BuildConfig/'"

          // login & push
          withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
            sh "ssh -o StrictHostKeyChecking=no ${BUILD_SERVER} 'echo \$PASS | docker login -u \$USER --password-stdin'"
            sh "ssh -o StrictHostKeyChecking=no ${BUILD_SERVER} 'docker push ${IMAGE_NAME}'"
          }
        }
      }
    }

    stage('Deploy with Docker Compose') {
      agent any
      steps {
        sshagent(['slave2']) {
          // copy deploy config
          sh "scp -o StrictHostKeyChecking=no -r DeployConfig ${DEPLOY_SERVER}:/home/ec2-user/"

          // make script executable
          sh "ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} 'chmod +x /home/ec2-user/DeployConfig/docker-compose-script.sh'"

          // docker login on deploy server
          withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
            sh "ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} 'echo \$PASS | docker login -u \$USER --password-stdin'"
          }

          // run compose (uses DOCKER_IMAGE env)
          sh "ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} 'bash /home/ec2-user/DeployConfig/docker-compose-script.sh ${IMAGE_NAME}'"
        }
      }
    }
  }
}
