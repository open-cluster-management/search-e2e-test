# Copyright (c) 2020 Red Hat, Inc.

FROM cypress/included:8.3.0 as production
# FROM registry.access.redhat.com/ubi8/nodejs-14:1

USER root

RUN mkdir -p /search-e2e-tests/cypress_cache
ENV CYPRESS_CACHE_FOLDER=/search-e2e/cypress_cache

WORKDIR /search-e2e-tests

COPY package.json ./
COPY package-lock.json ./
COPY cypress.json ./
COPY jest.config.js ./
COPY start-tests.sh ./
COPY download-clis.sh ./
COPY config ./config
COPY tests ./tests
COPY build/rbac-setup.sh ./
COPY build/rbac-clean.sh ./

RUN apt-get install libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 libxtst6 xauth xvfb

RUN npm install --unsafe-perm=true --allow-root cypress@8.4.1
RUN npm install cypress-grep \
    cypress-multi-reporters \
    cypress-terminal-report \
    cypress-wait-until \
    @cypress/code-coverage \
    mocha \
    mocha-junit-reporter \
    mochawesome \
    mochawesome-merge

RUN sh download-clis.sh

# Make the directory writable by non-root users
RUN chmod -R go+w /search-e2e-tests

# RUN ["chmod", "+x", "start-tests.sh"]

ENTRYPOINT ["./start-tests.sh"]
