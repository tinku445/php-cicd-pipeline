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

          // 1) Copy build context to Build EC2
          sh "scp -o StrictHostKeyChecking=no -r BuildConfig ${BUILD_SERVER}:/home/ec2-user/"

          // 2) Ensure Docker is installed & running
          sh "ssh -o StrictHostKeyChecking=no ${BUILD_SERVER} 'bash /home/ec2-user/BuildConfig/docker-script.sh'"

          // 3) Build image
          sh "ssh -o StrictHostKeyChecking=no ${BUILD_SERVER} 'docker build -t ${IMAGE_NAME} /home/ec2-user/BuildConfig/'"

          // 4) Login to Docker Hub on the Build host and push
          withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
            sh """
              ssh -o StrictHostKeyChecking=no ${BUILD_SERVER} 'set -e
                umask 077
                cat > /tmp/dh.pass << "EOF"
${DH_PASS}
EOF
                docker login -u ${DH_USER} --password-stdin < /tmp/dh.pass
                rm -f /tmp/dh.pass
              '
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

          // 1) Copy DeployConfig to Deploy EC2
          sh "scp -o StrictHostKeyChecking=no -r DeployConfig ${DEPLOY_SERVER}:/home/ec2-user/"

          // 2) Ensure the deploy script is executable
          sh "ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} 'chmod +x /home/ec2-user/DeployConfig/docker-compose-script.sh'"

          // 3) Login to Docker Hub on Deploy EC2
          withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
            sh """
              ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} 'set -e
                umask 077
                cat > /tmp/dh.pass << "EOF"
${DH_PASS}
EOF
                docker login -u ${DH_USER} --password-stdin < /tmp/dh.pass
                rm -f /tmp/dh.pass
              '
            """
          }

          // 4) Run compose (uses DOCKER_IMAGE passed as arg)
          sh "ssh -o StrictHostKeyChecking=no ${DEPLOY_SERVER} 'bash /home/ec2-user/DeployConfig/docker-compose-script.sh ${IMAGE_NAME}'"
        }
      }
    }
  }
}
