#!/bin/bash
# Copyright (c) 2021 Red Hat, Inc.
# Copyright Contributors to the Open Cluster Management project

###############################################################################
# Test Setup
###############################################################################

echo -e "Shared dir: $SHARED_DIR\n"

ls -la

# Test env
export BROWSER=chrome
export OPTIONS_HUB_KUBECONFIG=${SHARED_DIR}/hub-1.kc
export OPTIONS_KUBECONFIG_MOUNT_PATH=${SHARED_DIR}/managed-1.kc
export OPTIONS_MANAGED_KUBECONFIG=${OPTIONS_KUBECONFIG_MOUNT_PATH}
export PROW_MODE=true
export SKIP_API_TEST=false
export SKIP_UI_TEST=false
export TEST_MODE=BVT

# Hub cluster
HUB_CREDS=$(cat ${SHARED_DIR}/hub-1.json)
export OPTIONS_HUB_API_URL=$(yq e '.api_url' $SHARED_DIR/hub-1.json)
export OPTIONS_HUB_CONSOLE_URL=$(yq e '.console_url' $SHARED_DIR/hub-1.json)
export OPTIONS_HUB_BASEDOMAIN=${OPTIONS_HUB_CONSOLE_URL:39}
export OPTIONS_HUB_USER=$(yq e '.username' $SHARED_DIR/hub-1.json)
export OPTIONS_HUB_PASSWORD=$(yq e '.password' $SHARED_DIR/hub-1.json)

# Managed cluster
MANAGED_CREDS=$(cat ${SHARED_DIR}/managed-1.json)
export OPTIONS_MANAGED_API_URL=$(yq e '.api_url' $SHARED_DIR/managed-1.json)
export OPTIONS_MANAGED_CONSOLE_URL=$(yq e '.console_url' $SHARED_DIR/managed-1.json)
export OPTIONS_MANAGED_BASEDOMAIN=${OPTIONS_MANAGED_CONSOLE_URL:39}
export OPTIONS_MANAGED_USER=$(yq e '.username' $SHARED_DIR/managed-1.json)
export OPTIONS_MANAGED_PASSWORD=$(yq e '.password' $SHARED_DIR/managed-1.json)

echo -e "\nRunning Search-e2e tests in ${TEST_MODE} test mode. Preparing to run e2e tests."
./start-tests.sh

echo "TODO: Uploading test results to AWS S3 bucket."
# source ./build/upload-to-s3.sh
# install_aws_cli
# upload_s3

# echo "Test results uploaded to: https://s3.console.aws.amazon.com/s3/buckets/search-e2e-results?region=us-east-1&prefix=prow-${PROW_BUILD_ID}/&showversions=false"
