#!/bin/bash
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
export REPO=$DOCKER_USERNAME/vizzy
docker push $REPO:$TRAVIS_COMMIT
docker tag $REPO:$TRAVIS_COMMIT $REPO:latest
docker push $DOCKER_USERNAME/vizzy:latest