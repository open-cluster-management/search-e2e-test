#!/bin/bash

###############################################################################
# Copyright (c) 2020 Red Hat, Inc.
###############################################################################

echo "Initiating tests..."

if [ -z "$BROWSER" ]; then
  echo "BROWSER not exported; setting to 'chrome (options available: 'chrome', 'firefox')'"
  export BROWSER="chrome"
fi

# # check and load options.yaml
# OPTIONS_FILE=/resources/options.yaml
# if [ -f $OPTIONS_FILE ]; then
#   echo "Processing options file..."
#   BASE_DOMAIN=`yq r $OPTIONS_FILE 'options.hub.baseDomain'`
#   export CYPRESS_BASE_URL="https://multicloud-console.apps.$BASE_DOMAIN"
#   export OPTIONS_HUB_BASEDOMAIN="https://api.$BASE_DOMAIN:6443"
#   export OPTIONS_HUB_USER=`yq r $OPTIONS_FILE 'options.hub.user'`
#   export OPTIONS_HUB_PASSWORD=`yq r $OPTIONS_FILE 'options.hub.password'`,
# fi

echo "Logging into Kube API server $OPTIONS_HUB_BASEDOMAIN..."
oc login --server="https://api.$OPTIONS_HUB_BASEDOMAIN:6443 -u $OPTIONS_HUB_USER -p $OPTIONS_HUB_PASSWORD --insecure-skip-tls-verify"

echo "Running tests on https://multicloud-console.apps.$OPTIONS_HUB_BASEDOMAIN"
testCode=0
npx cypress run --browser $BROWSER --headless --spec ./tests/cypress/tests/**/*.spec.js
testCode=$?

mkdir /results
mkdir /results/recordings

echo "Merging xml reports..."
npm run test:merge-xml
cp ./tests/test-output/*.xml /results
ls -al /results

echo "Copying recordings to results"
cp ./tests/cypress/videos/**/*.mp4 /results/recordings
ls -al /results/recordings

exit $testCode
