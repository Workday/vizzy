#!/bin/sh -x

while [ $# -gt 0 ]; do
  case "$1" in
    --api-server=*)
      api_server="${1#*=}"
      ;;
    --bearer-token=*)
      bearer_token="${1#*=}"
      ;;
    --rails-env=*)
      rails_env="${1#*=}"
      ;;
    --vizzy-version=*)
      vizzy_version="${1#*=}"
      ;;
    --namespace=*)
      namespace="${1#*=}"
      ;;
    --vizzy-uri=*)
      vizzy_uri="${1#*=}"
      ;;
    --replica-pods=*)
      replica_pods="${1#*=}"
      ;;
    --memory=*)
      memory="${1#*=}"
      ;;
    --docker-registry=*)
      docker_registry="${1#*=}"
      ;;
    --run-tests=*)
      run_tests="${1#*=}"
      ;;
    *)
      printf "***************************\n"
      printf "* Error: Invalid argument.*\n"
      printf "***************************\n"
      exit 1
  esac
  shift
done

export VIZZY_VERSION=$vizzy_version
export VIZZY_URI=$vizzy_uri
export VIZZY_REPLICA_PODS=$replica_pods
export VIZZY_REQUESTS_MEMORY=$memory
export VIZZY_LIMITS_MEMORY=$memory
export RAILS_ENV=$rails_env
export DOCKER_REGISTRY=$docker_registry

#k config --kubeconfig=k8sconfig set-cluster k8s --server=$api_server
#k config --kubeconfig=k8sconfig set-credentials jenkins --token=$bearer_token
#k config --kubeconfig=k8sconfig set-context k8s --cluster=k8s --user=jenkins
#k config --kubeconfig=k8sconfig use-context k8s

export KUBECONFIG=~/Desktop/kubeconfig

./render-template.sh kubernetes-vizzy-config.template.yaml > vizzy-config.yaml
./render-template.sh kubernetes-postgres-config.template.yaml > postgres-config.yaml

kubectl --insecure-skip-tls-verify=true apply -f vizzy-pvc.yaml
kubectl --insecure-skip-tls-verify=true apply -f postgres-config.yaml
kubectl --insecure-skip-tls-verify=true apply -f vizzy-config.yaml

rm vizzy-config.yaml
rm postgres-config.yaml

sleep 30

# Get the running visual pod and run the tests inside the pod
TEST_POD=$(kubectl --insecure-skip-tls-verify=true get pods | grep -m1 vizzy | awk '{print $1}')
echo ${TEST_POD}
kubectl --insecure-skip-tls-verify=true exec ${TEST_POD} rake db:migrate

if [ $? -ne 0 ]; then
    echo "Could not run migrations, pod does not exist. Exiting 1..."
    exit 1
fi

if [ "$run_tests" = true ] ; then
    echo 'Running unit tests...'
    kubectl --insecure-skip-tls-verify=true exec ${TEST_POD} rake test
    TEST_STATUS=$?

    if [ ${TEST_STATUS} -ne 0 ]; then
        echo "Unit Tests Failed!"
    #   exit ${TEST_STATUS}
    else
        echo "Unit Tests Passed!"
    fi

    # TODO: Enable system tests on CI
    #kubectl --insecure-skip-tls-verify=true exec ${TEST_POD} rails test:system --namespace=$namespace
    #TEST_STATUS=$?
    #
    #if [ ${TEST_STATUS} -ne 0 ]; then
    #   echo "System Tests Failed!"
    #else
    #   echo "System Tests Passed!"
    #fi

    # Clean up deployment so nothing is left running
    kubectl --insecure-skip-tls-verify=true delete deployment vizzy
    kubectl --insecure-skip-tls-verify=true delete deployment postgres

    exit ${TEST_STATUS}
fi