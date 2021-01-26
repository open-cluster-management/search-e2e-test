#!/bin/bash

# Copyright (c) 2020 Red Hat, Inc


function install_aws_cli() {
     echo " >> BEFORE ls /home/travis/bin"
    ls /home/travis/bin

    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q -o awscliv2.zip
    ./aws/install -i ./aws-cli -b /home/travis/bin

    echo "Validate AWS cli install running [ /home/travis/bin/aws --version ]"
    ./home/travis/bin/aws --version
    echo " >> ls ./aws-cli/v2"
    ls aws-cli/v2
    echo " >> ls /home/travis/bin"
    ls /home/travis/bin

    chmod +x /home/travis/bin/aws
}

# copies the test results to the search-e2e-test S3 bucket
function upload_s3() {
    install_aws_cli
    echo "Uploading files to AWS S3 bucket.  search-e2e-test/travis-${TRAVIS_BUILD_ID}"  

    ./home/travis/bin/aws s3 sync ./search-test-results s3://search-e2e-results/travis-${TRAVIS_BUILD_ID}
}