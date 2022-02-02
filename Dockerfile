# Copyright (c) 2020 Red Hat, Inc.
FROM registry.ci.openshift.org/open-cluster-management/builder:nodejs14-linux AS builder
FROM cypress/included:8.5.0 AS production
FROM mikefarah/yq:4 as yq

USER root

COPY --from=yq /usr/bin/yq /usr/local/bin/yq

RUN mkdir -p /search-e2e/cypress_cache
ENV CYPRESS_CACHE_FOLDER=/search-e2e/cypress_cache
WORKDIR /search-e2e

COPY package.json .
COPY package-lock.json .
COPY cypress.json .
COPY jest.config.js .
COPY start-tests.sh .
COPY download-clis.sh .
COPY config ./config
COPY tests ./tests
COPY build ./build
COPY cicd-scripts/run-prow-e2e.sh .
COPY cicd-scripts/run-prow-unit.sh .

RUN npm ci
RUN sh download-clis.sh

RUN chmod -R go+w /search-e2e

RUN ["chmod", "+x", "start-tests.sh"]

ENTRYPOINT ["./start-tests.sh"]
