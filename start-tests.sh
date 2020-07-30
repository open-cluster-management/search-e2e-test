#!/bin/bash

###############################################################################
# Copyright (c) 2020 Red Hat, Inc.
###############################################################################

echo "Initiating tests..."

if [ -z "$BROWSER" ]; then
  echo "BROWSER not exported; setting to 'chrome (options available: 'chrome', 'firefox')'"
  export BROWSER="chrome"
fi

# local - - check and load options.yaml
OPTIONS_FILE=tests/resources/options.yaml
if [ -f $OPTIONS_FILE ]; then
  echo "Processing options file..."
  export CYPRESS_OPTIONS_HUB_BASEDOMAIN=`yq r $OPTIONS_FILE 'options.hub.baseDomain'`
  export CYPRESS_OPTIONS_HUB_USER=`yq r $OPTIONS_FILE 'options.hub.user'`
  export CYPRESS_OPTIONS_HUB_PASSWORD=`yq r $OPTIONS_FILE 'options.hub.password'`
fi

echo "Logging into Kube API server"
oc login --server=https://api.${CYPRESS_OPTIONS_HUB_BASEDOMAIN}:6443 -u $CYPRESS_OPTIONS_HUB_USER -p $CYPRESS_OPTIONS_HUB_PASSWORD --insecure-skip-tls-verify

echo "Running tests on https://multicloud-console.apps.$CYPRESS_OPTIONS_HUB_BASEDOMAIN"
testCode=0

# Try to install binary
npx cypress install
npx cypress run --browser $BROWSER --headless --spec ./tests/cypress/tests/**/*.spec.js --reporter cypress-multi-reporters

testCode=$?

mkdir -p results/recordings

echo "Merging xml reports..."
npm run test:merge-xml
cp ./tests/test-output/cypress/**/*.xml ./results
ls -al ./results

echo "Copying recordings to results"
cp ./tests/cypress/**/*.js.mp4 ./results/recordings
ls -al ./results/recordings

exit $testCode
