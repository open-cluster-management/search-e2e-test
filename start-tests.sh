#!/bin/bash

###############################################################################
# Copyright (c) 2020 Red Hat, Inc.
###############################################################################
echo "Initiating Search E2E tests..."

section_title () {
  printf "\n$(tput bold)$1 $(tput sgr0)\n"
}

if [ -z "$BROWSER" ]; then
  echo "BROWSER not exported; setting to 'chrome' (options available: 'chrome', 'firefox')"
  export BROWSER="chrome"
fi

# Load test config mounted at /resources/options.yaml
OPTIONS_FILE=/resources/options.yaml
USER_OPTIONS_FILE=./options.yaml

if [ -f $OPTIONS_FILE ]; then
  echo "Using test config from: $OPTIONS_FILE"
  export CYPRESS_OPTIONS_HUB_BASEDOMAIN=`yq e '.options.hub.baseDomain' $OPTIONS_FILE`
  export CYPRESS_OPTIONS_HUB_USER=`yq e '.options.hub.user' $OPTIONS_FILE`
  export CYPRESS_OPTIONS_HUB_PASSWORD=`yq e '.options.hub.password' $OPTIONS_FILE`
  export OPTIONS_HUB_BASEDOMAIN=`yq e '.options.hub.baseDomain' $OPTIONS_FILE`
  export OPTIONS_HUB_USER=`yq e '.options.hub.user' $OPTIONS_FILE`
  export OPTIONS_HUB_PASSWORD=`yq e '.options.hub.password' $OPTIONS_FILE`
elif [ -f $USER_OPTIONS_FILE ]; then
  echo "Using test config from: $USER_OPTIONS_FILE"
  export CYPRESS_OPTIONS_HUB_BASEDOMAIN=`yq e '.options.hub.baseDomain' $USER_OPTIONS_FILE`
  export CYPRESS_OPTIONS_HUB_USER=`yq e '.options.hub.user' $USER_OPTIONS_FILE`
  export CYPRESS_OPTIONS_HUB_PASSWORD=`yq e '.options.hub.password' $USER_OPTIONS_FILE`
  export OPTIONS_HUB_BASEDOMAIN=`yq e '.options.hub.baseDomain' $USER_OPTIONS_FILE`
  export OPTIONS_HUB_USER=`yq e '.options.hub.user' $USER_OPTIONS_FILE`
  export OPTIONS_HUB_PASSWORD=`yq e '.options.hub.password' $USER_OPTIONS_FILE`
else
  echo -e "Options file does not exist, using test config from environment variables.\n"
fi

export CYPRESS_BASE_URL=https://multicloud-console.apps.$CYPRESS_OPTIONS_HUB_BASEDOMAIN

echo -e "Running tests with the following environment:\n"
echo -e "\tCYPRESS_OPTIONS_HUB_BASEDOMAIN : $CYPRESS_OPTIONS_HUB_BASEDOMAIN"
echo -e "\tCYPRESS_OPTIONS_HUB_BASE_URL   : $CYPRESS_BASE_URL"
echo -e "\tCYPRESS_OPTIONS_HUB_USER       : $CYPRESS_OPTIONS_HUB_USER\n"

if [[ -z $OPTIONS_MANAGED_BASEDOMAIN || -z $OPTIONS_MANAGED_USER || -z $OPTIONS_MANAGED_PASSWORD ]]; then
   echo 'One or more variables are undefined. Copying kubeconfigs...'
   cp /opt/.kube/import-kubeconfig ./config/import-kubeconfig
else
  echo "Logging into the managed cluster using credentials and generating the kubeconfig..."
  mkdir ./import-kubeconfig && touch ./import-kubeconfig/kubeconfig
  export KUBECONFIG=$(pwd)/import-kubeconfig/kubeconfig
  export OPTIONS_MANAGED_URL="https://api.$OPTIONS_MANAGED_BASEDOMAIN:6443"
  oc login --server=$OPTIONS_MANAGED_URL -u $OPTIONS_MANAGED_USER -p $OPTIONS_MANAGED_PASSWORD --insecure-skip-tls-verify
  unset KUBECONFIG
  echo "Copying managed cluster kubeconfig to ./cypress/config/import-kubeconfig ..."
  cp ./import-kubeconfig/* ./config/import-kubeconfig
fi

echo -e "\nLogging into Kube API server\n"
oc login --server=https://api.${CYPRESS_OPTIONS_HUB_BASEDOMAIN}:6443 -u $CYPRESS_OPTIONS_HUB_USER -p $CYPRESS_OPTIONS_HUB_PASSWORD --insecure-skip-tls-verify

testCode=0

echo "Checking RedisGraph deployment."
installNamespace=`oc get mch -A -o jsonpath='{.items[0].metadata.namespace}'`
rgstatus=`oc get srcho searchoperator -o jsonpath="{.status.deployredisgraph}" -n ${installNamespace}`
if [ "$rgstatus" == "true" ]; then
  echo "RedisGraph deployment is enabled."
else
  echo "RedisGraph deployment disabled, enabling and waiting 60 seconds for the search-redisgraph-0 pod."
  oc set env deploy search-operator DEPLOY_REDISGRAPH="true" -n $installNamespace
  sleep 60
fi

# We are caching the cypress binary for containerization, therefore it does not need npx. However, locally we need it.
HEADLESS="--headless"
if [[ "$LIVE_MODE" == true ]]; then
  HEADLESS=""
fi

if [ -z "$NODE_ENV" ]; then
  export NODE_ENV="production" || set NODE_ENV="production"
fi

if [ -z "$SKIP_API_TEST" ]; then
  echo -e "\nSKIP_API_TEST not exported; setting to false (set SKIP_API_TEST to true, if you wish to skip the API tests)"
  export SKIP_API_TEST=false
fi

if [ -z "$SKIP_UI_TEST" ]; then
  echo -e "SKIP_UI_TEST not exported; setting to false (set SKIP_UI_TEST to true, if you wish to skip the UI tests)\n"
  export SKIP_UI_TEST=false
fi

echo -e "Setting env to run in: $NODE_ENV\n"

echo "Create RBAC users"
if [ -f /rbac-setup.sh ]; then
  chmod +x /rbac-setup.sh
  source /rbac-setup.sh
else # DEV
  chmod +x build/rbac-setup.sh
  source build/rbac-setup.sh
fi

if [ "$SKIP_API_TEST" == false ]; then 
  section_title "Running Search API tests."
  npm run test:api || exit 1
else
  echo -e "\nSKIP_API_TEST was set to true. Skipping API tests\n"
fi

if [ -z "$RECORD" ]; then
  echo -e "RECORD not exported; setting to false (set RECORD to true, if you wish to view results within dashboard)\n"
  export RECORD=false
fi

if [ "$SKIP_UI_TEST" == false ]; then
  if [ "$RECORD" == true ]; then
    echo "Preparing to run test within record mode. (Results will be displayed within dashboard)"
    cypress run --record --key $RECORD_KEY --browser $BROWSER $HEADLESS --spec "./tests/cypress/tests/**/*.spec.js" --reporter cypress-multi-reporters --env NODE_ENV=$NODE_ENV
  fi

  section_title "Running Search UI tests."
  if [ "$NODE_ENV" == "development" ]; then
    cypress run --browser $BROWSER $HEADLESS --spec "./tests/cypress/tests/**/*.spec.js" --reporter cypress-multi-reporters --env NODE_ENV=$NODE_ENV
  elif [ "$NODE_ENV" == "debug" ]; then
    cypress open --browser $BROWSER --config numTestsKeptInMemory=0 --env NODE_ENV=$NODE_ENV
  else 
    cypress run --browser $BROWSER $HEADLESS --spec "./tests/cypress/tests/**/*.spec.js" --reporter cypress-multi-reporters --env NODE_ENV=$NODE_ENV
  fi
else
  echo -e "SKIP_UI_TEST was set to true. Skipping UI tests\n"
fi

testCode=$?

if [[ "$SKIP_UI_TEST" == false && "$SKIP_API_TEST" == false ]]; then
  section_title "Merging XML and JSON reports..."
  npm run test:merge-reports
  ls -R results
fi

echo "Clean up RBAC setup"
if [ -f /rbac-clean.sh ]; then
  chmod +x /rbac-clean.sh
  source /rbac-clean.sh
else # DEV
  chmod +x build/rbac-clean.sh
  source build/rbac-clean.sh
fi

exit $testCode
