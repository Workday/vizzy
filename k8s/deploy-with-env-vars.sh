#!/usr/bin/env bash

API_SERVER=https://kubernetes.syman.megaleo.com
NAMESPACE=visual-dev
REPLICA_PODS=3
VIZZY_URI=vizzy-dev.syman.megaleo.com
MEMORY="8Gi"
RAILS_ENV=production
RUN_TESTS=false
DOCKER_REGISTRY=docker-dev-artifactory.workday.com

./deploy-vizzy.sh --api-server=$API_SERVER --rails-env=$RAILS_ENV --vizzy-version=v3.3.6 --namespace=$NAMESPACE --vizzy-uri=$VIZZY_URI --replica-pods=$REPLICA_PODS --memory=$MEMORY --docker-registry=$DOCKER_REGISTRY --run-tests=$RUN_TESTS