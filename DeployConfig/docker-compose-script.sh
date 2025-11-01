#!/usr/bin/env bash
set -e
DOCKER_IMAGE="$1"
export DOCKER_IMAGE
docker compose -f /home/ec2-user/DeployConfig/docker-compose.yaml up -d
