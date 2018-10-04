#!/usr/bin/env bash

API_SERVER=https://kubernetes.syman.megaleo.com
NAMESPACE=visual-android
REPLICA_PODS=5
VIZZY_URI=vizzy-android.syman.megaleo.com
MEMORY="12Gi"
RAILS_ENV=production
RUN_TESTS=false
DOCKER_REGISTRY=docker-dev-artifactory.workday.com

./deploy-vizzy.sh --api-server=$API_SERVER --rails-env=$RAILS_ENV --vizzy-version=v3.1.1 --namespace=$NAMESPACE --vizzy-uri=$VIZZY_URI --replica-pods=$REPLICA_PODS --memory=$MEMORY --docker-registry=$DOCKER_REGISTRY --run-tests=$RUN_TESTS