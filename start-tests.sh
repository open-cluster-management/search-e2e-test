#!/bin/bash

###############################################################################
# Copyright (c) 2020 Red Hat, Inc.
###############################################################################

####################
## COLORS
####################
CYAN="\033[0;36m"
GREEN="\033[0;32m"
PURPLE="\033[0;35m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
NC="\033[0m"

log_color () {
  case $1 in
    cyan)
      echo -e "${CYAN}$2 ${NC}"$3
    ;;
    green)
      echo -e "${GREEN}$2 ${NC}"$3
    ;;
    purple)
      echo -e "${PURPLE}$2 ${NC}"$3
    ;;
    red)
      echo -e "${RED}$2 ${NC}"$3
    ;;
    yellow)
      echo -e "${YELLOW}$2 ${NC}"$3
    ;;
  esac
}

log_color "cyan" "Initiating Search E2E tests...\n"

# Set browser for UI testing.
if [[ -z $BROWSER ]]; then
  log_color "purple" "BROWSER" "not exported; setting to 'chrome' (options available: 'chrome', 'firefox')\n"
  export BROWSER=chrome
else
  log_color "purple" "BROWSER set (running in $BROWSER)\n"
fi

# Create directory for kubeconfigs.
mkdir -p ./kube/config

# Load test config mounted at /resources/options.yaml
OPTIONS_FILE=/resources/options.yaml
USER_OPTIONS_FILE=./resources/options.yaml

# Load test kubeconfig mounted at /opt/.kube/config and /opt/.kube/import-kubeconfig
OPTIONS_HUB_KUBECONFIG=${OPTIONS_HUB_KUBECONFIG:-'/opt/.kube/config'}
OPTIONS_MANAGED_KUBECONFIG=${OPTIONS_MANAGED_KUBECONFIG:-'/opt/.kube/import-kubeconfig'}

# Check to see if the test config options file is mounted/available.
if [[ -f $OPTIONS_FILE ]]; then
  log_color "yellow" "Using test config from: $OPTIONS_FILE\n"
  export OPTIONS_HUB_BASEDOMAIN=`yq e '.options.hub.baseDomain' $OPTIONS_FILE`
  export OPTIONS_HUB_KUBECONTEXT=`yq e '.options.hub.kubecontext' $OPTIONS_FILE`
  export OPTIONS_HUB_OC_IDP=`yq e '.options.identityProvider' $OPTIONS_FILE`
  export OPTIONS_HUB_PASSWORD=`yq e '.options.hub.password' $OPTIONS_FILE`
  export OPTIONS_HUB_USER=`yq e '.options.hub.user' $OPTIONS_FILE`
  export OPTIONS_MANAGED_BASEDOMAIN=`yq e '.options.clusters[0].basedomain' $OPTIONS_FILE`
  export OPTIONS_MANAGED_CLUSTER_NAME=`yq e '.options.clusters[0].name' $OPTIONS_FILE`
  export OPTIONS_MANAGED_KUBECONFIG=`yq e '.options.clusters[0].kubeconfig' $OPTIONS_FILE`
elif [[ -f $USER_OPTIONS_FILE ]]; then
  log_color "yellow" "Using test config from: $USER_OPTIONS_FILE\n"
  export OPTIONS_HUB_BASEDOMAIN=`yq e '.options.hub.baseDomain' $USER_OPTIONS_FILE`
  export OPTIONS_HUB_KUBECONTEXT=`yq e '.options.hub.kubecontext' $USER_OPTIONS_FILE`
  export OPTIONS_HUB_OC_IDP=`yq e '.options.identityProvider' $USER_OPTIONS_FILE`
  export OPTIONS_HUB_PASSWORD=`yq e '.options.hub.password' $USER_OPTIONS_FILE`
  export OPTIONS_HUB_USER=`yq e '.options.hub.user' $USER_OPTIONS_FILE`
  export OPTIONS_MANAGED_BASEDOMAIN=`yq e '.options.clusters[0].basedomain' $USER_OPTIONS_FILE`
  export OPTIONS_MANAGED_CLUSTER_NAME=`yq e '.options.clusters[0].name' $USER_OPTIONS_FILE`
  export OPTIONS_MANAGED_KUBECONFIG=`yq e '.options.clusters[0].kubeconfig' $USER_OPTIONS_FILE`
else
  log_color "yellow" "Options file does not exist, checking to see if the test can be configured with environment variables.\n"
fi

# Check to see if OPTIONS_HUB_OC_IDP is unset or null.
if [[ -z $OPTIONS_HUB_OC_IDP || "$OPTIONS_HUB_OC_IDP" == "null" ]]; then
  log_color "purple" "OPTIONS_HUB_OC_IDP" "not exported or null; setting to 'kube:admin' (set ${PURPLE}OPTIONS_HUB_OC_IDP${NC} to execute the test with target identity provider)"
  export OPTIONS_HUB_OC_IDP=kube:admin

  log_color "purple" "OPTIONS_HUB_USER" "setting to default user: 'kubeadmin'\n"
  export OPTIONS_HUB_USER=kubeadmin
else
  log_color "purple" "OPTIONS_HUB_OC_IDP" "detected, using $OPTIONS_HUB_OC_IDP for test.\n"
fi

# Check to see if OPTIONS_HUB_BASEDOMAIN, OPTIONS_HUB_USER, or OPTIONS_HUB_PASSWORD are missing. We need these to run the UI test.
if [[ -z $OPTIONS_HUB_BASEDOMAIN || -z $OPTIONS_HUB_USER || -z $OPTIONS_HUB_PASSWORD ]]; then
  log_color "red" "One or more exported variables are undefined for hub cluster." "(set ${PURPLE}OPTIONS_HUB_BASEDOMAIN, OPTIONS_HUB_USER, and OPTIONS_HUB_PASSWORD${NC} to execute the test with environment variables)\n"

  # Check to see if the kubeconfig for the hub cluster is available.
  if [[ ! -f $OPTIONS_HUB_KUBECONFIG ]]; then
    log_color "red" "The kubeconfig file for the hub cluster was not located." "(set ${PURPLE}KUBECONFIG${NC} to ${YELLOW}$OPTIONS_HUB_KUBECONFIG${NC} and oc login to create kubeconfig file)"
    exit 1
  else
    # To run the E2E test, we need the password to log into the UI. If it's not exported or available from the options.yaml file, skip the UI test.
    if [[ -z $OPTIONS_HUB_PASSWORD || "$OPTIONS_HUB_PASSWORD" == "null" ]]; then
      log_color "purple" "OPTIONS_HUB_PASSWORD" "not exported; (${PURPLE}OPTIONS_HUB_PASSWORD${NC} is required to login into the ACM console... Skipping UI test)\n"
      export SKIP_UI_TEST=true
    fi

    echo -e "Kubeconfig file detected at: $OPTIONS_HUB_KUBECONFIG => ${YELLOW}copying to ./kube/config/hub-kubeconfig${NC}"
    cp $OPTIONS_HUB_KUBECONFIG ./kube/config/hub-kubeconfig
    export OPTIONS_HUB_KUBECONFIG=./kube/config/hub-kubeconfig

    # Check to see if there are any kubecontext to be used from the hub cluster kubeconfig.
    if [[ -z $OPTIONS_HUB_KUBECONTEXT || "$OPTIONS_HUB_KUBECONTEXT" == "null" ]]; then
      HUB_CLUSTER=($(oc config get-clusters --kubeconfig=$OPTIONS_HUB_KUBECONFIG))
      export OPTIONS_HUB_KUBECONTEXT=default/${HUB_CLUSTER[1]}/$OPTIONS_HUB_OC_IDP
    fi

    echo -e
    log_color "cyan" "Switching context to log into Kube API server"
    oc config use-context --kubeconfig=$OPTIONS_HUB_KUBECONFIG $OPTIONS_HUB_KUBECONTEXT
    
    export USE_HUB_KUBECONFIG=true
    export OPTIONS_HUB_BASEDOMAIN=$(oc whoami --show-server=true | cut -d'.' -f2- | cut -d':' -f1)

    log_color "purple" "HUB CLUSTER:" "$OPTIONS_HUB_BASEDOMAIN"
  fi
else
  echo -e "Environment variables detected for hub cluster. Configuring tests to execute with exported variables."
fi

# Export variables to cypress.
export CYPRESS_OPTIONS_HUB_BASEDOMAIN=$OPTIONS_HUB_BASEDOMAIN
export CYPRESS_OPTIONS_HUB_KUBECONTEXT=$OPTIONS_HUB_KUBECONTEXT
export CYPRESS_OPTIONS_HUB_OC_IDP=$OPTIONS_HUB_OC_IDP
export CYPRESS_OPTIONS_HUB_PASSWORD=$OPTIONS_HUB_PASSWORD
export CYPRESS_OPTIONS_HUB_USER=$OPTIONS_HUB_USER
export CYPRESS_USE_HUB_KUBECONFIG=$USE_HUB_KUBECONFIG

# Export base url for cluster.
export BASE_URL=https://multicloud-console.apps.$OPTIONS_HUB_BASEDOMAIN
export CYPRESS_BASE_URL=$BASE_URL

echo -e

log_color "cyan" "Running tests with the following cluster environment:\n"
log_color "purple" "\tCYPRESS_OPTIONS_HUB_BASE_URL" "\t: $CYPRESS_BASE_URL"
log_color "purple" "\tCYPRESS_OPTIONS_HUB_BASEDOMAIN" "\t: $CYPRESS_OPTIONS_HUB_BASEDOMAIN"
log_color "purple" "\tCYPRESS_OPTIONS_HUB_OC_IDP" "\t: $CYPRESS_OPTIONS_HUB_OC_IDP"
log_color "purple" "\tCYPRESS_OPTIONS_HUB_USER" "\t: $CYPRESS_OPTIONS_HUB_USER\n"

if [[ ! -z $CYPRESS_OPTIONS_HUB_PASSWORD && "$CYPRESS_OPTIONS_HUB_PASSWORD" != "null" ]]; then
  log_color "cyan" "Logging into Kube API server."

  export KUBECONFIG=./kube/config/hub-kubeconfig
  touch $KUBECONFIG

  oc login --server=https://api.${CYPRESS_OPTIONS_HUB_BASEDOMAIN}:6443 -u $CYPRESS_OPTIONS_HUB_USER -p $CYPRESS_OPTIONS_HUB_PASSWORD --insecure-skip-tls-verify
  export OPTIONS_HUB_KUBECONFIG=$KUBECONFIG
  export CYPRESS_OPTIONS_HUB_KUBECONFIG=$OPTIONS_HUB_KUBECONFIG

  if [[ -f $OPTIONS_HUB_KUBECONFIG ]]; then
    echo -e "Succesfully detected hub cluster kubeconfig.\n"
  else
    echo -e "Failed to create or locate hub cluster kubeconfig.\n"
  fi

elif [[ ! -z $USE_HUB_KUBECONFIG && "$USE_HUB_KUBCONFIG" == true ]]; then
  ADD_KUBECONFIG="--kubeconfig=$OPTIONS_HUB_KUBECONFIG"
fi

export CYPRESS_ACM_VERSION=`oc get subscriptions.operators.coreos.com $ADD_KUBECONFIG -A -o yaml | grep currentCSV:\ advanced-cluster-management | awk '{$1=$1};1' | sed "s/currentCSV:\ advanced-cluster-management.v//"`
log_color "green" "Testing with ACM Version": "$CYPRESS_ACM_VERSION\n"

log_color "cyan" "Checking RedisGraph deployment."
installNamespace=`oc get subscriptions.operators.coreos.com $ADD_KUBECONFIG --all-namespaces | grep advanced-cluster-management | awk '{print $1}'`
rgstatus=`oc get srcho searchoperator -o jsonpath="{.status.deployredisgraph}" $ADD_KUBECONFIG -n $installNamespace`

if [[ "$rgstatus" == "true" ]]; then
  echo -e "RedisGraph deployment is enabled.\n"
else
  echo -e "RedisGraph deployment disabled, enabling and waiting 60 seconds for the search-redisgraph-0 pod.\n"
  oc set env deploy search-operator DEPLOY_REDISGRAPH="true" $ADD_KUBECONFIG -n $installNamespace
  sleep 60
fi

# Search for managed clusters.
MANAGED_CLUSTERS=($(oc get managedclusters $ADD_KUBECONFIG -o custom-columns='name:.metadata.name' --no-headers))

# Check to see if there are any managed cluster available.
if [[ ${#MANAGED_CLUSTERS[@]} == "1" && ${MANAGED_CLUSTERS[0]} =~ "local-cluster" ]]; then
  echo -e "No managable clusters detected for the hub cluster: $CYPRESS_OPTIONS_HUB_BASEDOMAIN.\n"
  export SKIP_MANAGED_CLUSTER_TEST=true
else
  echo -e "Detected clusters within the fleet: ${GREEN}${MANAGED_CLUSTERS[@]}${NC}\n"

  if [[ -z $OPTIONS_MANAGED_BASEDOMAIN || -z $OPTIONS_MANAGED_USER || -z $OPTIONS_MANAGED_PASSWORD ]]; then
    log_color "red" "One or more exported variables are undefined for imported cluster." "(set ${PURPLE}OPTIONS_MANAGED_BASEDOMAIN, OPTIONS_MANAGED_USER, and OPTIONS_MANAGED_PASSWORD${NC} to execute the test with environment variables)\n"

    # The mount path will be set by CICD.
    if [[ ! -z $OPTIONS_KUBECONFIG_MOUNT_PATH ]]; then
      echo -e "Detected kubeconfig mount path for imported cluster at: $OPTIONS_KUBECONFIG_MOUNT_PATH"
      OPTIONS_MANAGED_KUBECONFIG=$OPTIONS_KUBECONFIG_MOUNT_PATH
    fi

    # Check to see if the kubeconfig for the managed cluster is available.
    if [[ ! -f $OPTIONS_MANAGED_KUBECONFIG ]]; then
      log_color "red" "The kubeconfig file for imported cluster was not located." "(set ${PURPLE}KUBECONFIG${NC} to ${YELLOW}$OPTIONS_MANAGED_KUBECONFIG${NC} and oc login to create kubeconfig file)"
      echo -e "Skipping managed cluster test.\n"
      export SKIP_MANAGED_CLUSTER_TEST=true
    else
      # Exporting this variable so cypress will know to use the kubeconfig file for the imported cluster.
      export USE_MANAGED_KUBECONFIG=true
      export SKIP_MANAGED_CLUSTER_TEST=false

      echo -e "Kubeconfig file detected at: $OPTIONS_MANAGED_KUBECONFIG - ${YELLOW}copying to ./kube/config/import-kubeconfig${NC}\n"
      cp $OPTIONS_MANAGED_KUBECONFIG ./kube/config/import-kubeconfig
      export OPTIONS_MANAGED_KUBECONFIG=./kube/config/import-kubeconfig

      if [[ -z $OPTIONS_MANAGED_KUBECONTEXT || "$OPTIONS_MANAGED_KUBECONTEXT" == "null" ]]; then
        MANAGED_CLUSTER=($(oc config get-clusters --kubeconfig=$OPTIONS_MANAGED_KUBECONFIG))
        export OPTIONS_MANAGED_KUBECONTEXT=default/${MANAGED_CLUSTER[1]}/kube:admin
      fi

      log_color "cyan" "Switching context to log into Kube API server"
      oc config use-context --kubeconfig=$OPTIONS_MANAGED_KUBECONFIG $OPTIONS_MANAGED_KUBECONTEXT
      export OPTIONS_MANAGED_BASEDOMAIN=$(echo ${MANAGED_CLUSTER[1]} | cut -d'-' -f2- | cut -d':' -f1)
      export OPTIONS_MANAGED_USER=kubeadmin

      log_color "purple" "IMPORTED CLUSTER:" "$OPTIONS_MANAGED_BASEDOMAIN\n"
    fi
  else
    echo -e "Environment variables detected for managed cluster. Configuring tests to execute with imported cluster exported variables.\n"
    log_color "cyan" "Logging into the managed cluster using credentials and generating the kubeconfig..."

    OPTIONS_MANAGED_URL="https://api.$OPTIONS_MANAGED_BASEDOMAIN:6443"

    export KUBECONFIG=./kube/config/import-kubeconfig
    touch $KUBECONFIG
    
    oc login --server=$OPTIONS_MANAGED_URL -u $OPTIONS_MANAGED_USER -p $OPTIONS_MANAGED_PASSWORD --insecure-skip-tls-verify
    export OPTIONS_MANAGED_KUBECONFIG=$KUBECONFIG
    unset KUBECONFIG

    if [[ -f $OPTIONS_MANAGED_KUBECONFIG ]]; then
      echo -e "Successfully detected managed cluster kubeconfig.\n"
    else
      echo -e "Failed to create or locate managed cluster kubeconfig.\n"
    fi
  fi
fi

export KUBECONFIG=$OPTIONS_HUB_KUBECONFIG

export CYPRESS_OPTIONS_MANAGED_BASEDOMAIN=$OPTIONS_MANAGED_BASEDOMAIN
export CYPRESS_OPTIONS_MANAGED_CLUSTER_NAME=$OPTIONS_MANAGED_CLUSTER_NAME
export CYPRESS_OPTIONS_MANAGED_KUBECONFIG=$OPTIONS_MANAGED_KUBECONFIG
export CYPRESS_OPTIONS_MANAGED_KUBECONTEXT=$OPTIONS_MANAGED_KUBECONTEXT
export CYPRESS_OPTIONS_MANAGED_PASSWORD=$OPTIONS_MANAGED_PASSWORD
export CYPRESS_OPTIONS_MANAGED_USER=kubeadmin
export CYPRESS_SKIP_MANAGED_CLUSTER_TEST=$SKIP_MANAGED_CLUSTER_TEST
export CYPRESS_USE_MANAGED_KUBECONFIG=$USE_MANAGED_KUBECONFIG

log_color "cyan" "Running tests with the following imported cluster environment:\n"
log_color "purple" "\tCYPRESS_OPTIONS_MANAGED_BASEDOMAIN" "\t: $CYPRESS_OPTIONS_MANAGED_BASEDOMAIN"
log_color "purple" "\tCYPRESS_OPTIONS_MANAGED_CLUSTER_NAME" "\t: $CYPRESS_OPTIONS_MANAGED_CLUSTER_NAME"
log_color "purple" "\tCYPRESS_OPTIONS_MANAGED_USER" "\t\t: $CYPRESS_OPTIONS_MANAGED_USER\n"

testCode=0

if [[ -z $NODE_ENV ]]; then
  export NODE_ENV="production" || set NODE_ENV="production"
fi

log_color "green" "Setting env to run in:" "$NODE_ENV\n"

# Running canary test. Depending on the test mode, we want to filter the test related to that mode and all tests that are marked required.
if [[ "https://api.${CYPRESS_OPTIONS_HUB_BASEDOMAIN}:6443" =~ "canary" || "$TEST_ENV" == "canary" ]]; then
  log_color "yellow" "Canary cluster environment detected:"

  if [[ -z $TEST_MODE ]]; then
    log_color "purple" "TEST_MODE" "not exported; setting to 'BVT' (options available 'BVT', 'SMOKE')\n"
    TAGS="@CANARY+@REQUIRED @CANARY+@BVT"
    export TEST_MODE=BVT

  elif [[ "$TEST_MODE" == "BVT" ]]; then
    log_color "purple" "TEST_MODE" "set to @BVT - running test that are tagged with @CANARY, @REQUIRED, and @BVT.\n"
    TAGS="@CANARY+@REQUIRED @CANARY+@BVT"

  elif [[ "$TEST_MODE" == "smoke" ]]; then
    log_color "purple" "TEST_MODE" "set to @SMOKE - running test that are tagged with @CANARY, @REQUIRED, and @SMOKE.\n"
    TAGS="@CANARY+@REQUIRED @CANARY+@SMOKE"

  else
    log_color "purple" "TEST_MODE" "set to @$TEST_MODE - unknown option selected. Preparing to run all test. (options available 'BVT' or 'SMOKE')\n"
  fi

  if [[ -z $CYPRESS_TAGS_INCLUDE ]]; then
    export CYPRESS_TAGS_INCLUDE=$TAGS
  else
    export CYPRESS_TAGS_INCLUDE="$TAGS $CYPRESS_TAGS_INCLUDE"
  fi

  export TEST_ENV=canary
  export CYPRESS_TEST_ENV=$TEST_ENV
fi

if [[ "https://api.${CYPRESS_OPTIONS_HUB_BASEDOMAIN}:6443" =~ "openshiftapps.com" || "$TEST_ENV" == "rosa" ]]; then
  log_color "yellow" "ROSA cluster environment detected: excluding test that are tagged with @ROSA and @RBAC.\n"
  
  # Running rosa test. We want to run all tests that are marked rosa but exclude rbac.
  if [[ -z "$CYPRESS_TAGS_EXCLUDE" ]]; then
    export CYPRESS_TAGS_EXCLUDE="@ROSA+-@RBAC"
  else
    export CYPRESS_TAGS_EXCLUDE="@ROSA+-@RBAC $CYPRESS_TAGS_EXCLUDE"
  fi

  export TEST_ENV=rosa
  export CYPRESS_TEST_ENV=$TEST_ENV
fi

# We are caching the cypress binary for containerization, therefore it does not need npx. However, locally we need it.
DISPLAY="--headless"
if [[ "$LIVE_MODE" == true ]]; then
  DISPLAY="--headed"
fi

if [[ -z $SKIP_API_TEST ]]; then
  log_color "purple" "SKIP_API_TEST" "not exported; setting to false (set ${PURPLE}SKIP_API_TEST${NC} to true, if you wish to skip the API tests)"
  export SKIP_API_TEST=false
fi

if [[ -z $SKIP_UI_TEST ]]; then
  log_color "purple" "SKIP_UI_TEST" "not exported; setting to false (set ${PURPLE}SKIP_UI_TEST${NC} to true, if you wish to skip the UI tests)"
  export SKIP_UI_TEST=false
fi

echo -e

if [[ -z $CYPRESS_TAGS_INCLUDE ]]; then
  log_color "purple" "CYPRESS_TAGS_INCLUDE" "not exported; (set ${PURPLE}CYPRESS_TAGS_INCLUDE${NC} to include a test tags i.e ${YELLOW}@CANARY${NC}, if you wish to execute on a subset of tests)"
else
  log_color "purple" "Including tests that only contain the following tags: ${YELLOW}$CYPRESS_TAGS_INCLUDE${NC}\n"
  CYPRESS_TAGS=$CYPRESS_TAGS_INCLUDE
fi

if [ -z $CYPRESS_TAGS_EXCLUDE ]; then
  log_color "purple" "CYPRESS_TAGS_EXCLUDE" "not exported; (set ${PURPLE}CYPRESS_TAGS_EXCLUDE${NC} to include a test tags i.e ${YELLOW}@RBAC${NC}, if you wish to execute and exclude a subset of test from the run)\n"
else
  log_color "purple" "Excluding tests that only contain the following tags: ${YELLOW}$CYPRESS_TAGS_EXCLUDE${NC}"
fi

if [[ ! -z $CYPRESS_TAGS_INCLUDE || ! -z $CYPRESS_TAGS_EXCLUDE ]]; then
  CYPRESS_TAGS="$CYPRESS_TAGS_INCLUDE $CYPRESS_TAGS_EXCLUDE"

  echo -e "Executing tests with the following tags: $CYPRESS_TAGS\n"
fi

if [[ "$SKIP_API_TEST" == false ]]; then 
  log_color "cyan" "Running Search API tests."
  npm run test:api
else
  log_color "purple" "SKIP_API_TEST" "was set to true. Skipping API tests"
fi

echo -e

if [[ -z $RECORD ]]; then
  log_color "purple" "RECORD" "not exported; setting to false (set ${PURPLE}RECORD${NC} to true, if you wish to view results within dashboard)\n"
  export RECORD=false
fi

if [[ "$SKIP_UI_TEST" == false ]]; then
  # Displaying cypress environment variables, so we know all of the ones that are being passed successfully.
  env | grep "cypress_" -i
  echo -e

  log_color "cyan" "Create RBAC users"
  if [[ -f /rbac-setup.sh ]]; then
    chmod +x /rbac-setup.sh
    source /rbac-setup.sh
  else # DEV
    chmod +x build/rbac-setup.sh
    source build/rbac-setup.sh
  fi

  echo -e

  if [[ "$RECORD" == true ]]; then
    echo -e "Preparing to run test within record mode. (Results will be displayed within dashboard)\n"
    cypress run --record --key $RECORD_KEY --browser $BROWSER $DISPLAY --spec "./tests/cypress/tests/**/*.spec.js" --reporter cypress-multi-reporters --env NODE_ENV=$NODE_ENV,grepTags="${CYPRESS_TAGS:-}"
  fi

  log_color "cyan" "Running Search UI tests."
  if [ "$NODE_ENV" == "development" ]; then
    cypress run --browser $BROWSER $DISPLAY --spec "./tests/cypress/tests/**/*.spec.js" --reporter cypress-multi-reporters --env NODE_ENV=$NODE_ENV,grepTags="${CYPRESS_TAGS:-}"
  elif [ "$NODE_ENV" == "debug" ]; then
    cypress open --browser $BROWSER --config numTestsKeptInMemory=0 --env NODE_ENV=$NODE_ENV,grepTags=$CYPRESS_TAGS
  else
    cypress run --browser $BROWSER $DISPLAY --spec "./tests/cypress/tests/**/*.spec.js" --reporter cypress-multi-reporters --env NODE_ENV=$NODE_ENV,grepTags="${CYPRESS_TAGS:-}"
  fi
else
  log_color "purple" "SKIP_UI_TEST" "was set to true. Skipping UI tests\n"
fi

testCode=$?

if [[ "$SKIP_UI_TEST" == false && "$SKIP_API_TEST" == false ]]; then
  log_color "cyan" "Merging XML and JSON reports..."
  npm run test:merge-reports
  ls -R results
fi

if [[ "$SKIP_UI_TEST" == false ]]; then
  log_color "cyan" "Clean up RBAC setup"
  if [ -f /rbac-clean.sh ]; then
    chmod +x /rbac-clean.sh
    source /rbac-clean.sh
  else # DEV
    chmod +x build/rbac-clean.sh
    source build/rbac-clean.sh
  fi
fi

exit $testCode
