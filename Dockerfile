# Copyright (c) 2020 Red Hat, Inc.

FROM registry.ci.openshift.org/stolostron/builder:nodejs20-linux as builder
FROM mikefarah/yq:4.32.2 as yq
# Should match cypress version in package.json
FROM cypress/included:13.13.0 AS production

USER root

COPY --from=yq /usr/bin/yq /usr/local/bin/yq
COPY --from=builder /usr/bin/node /usr/bin/node

RUN mkdir -p /search-e2e/cypress_cache
ENV CYPRESS_CACHE_FOLDER=/search-e2e/cypress_cache
WORKDIR /search-e2e

COPY package.json .
COPY package-lock.json .
COPY cypress.config.json .
COPY jest.config.js .
COPY start-tests.sh .
COPY install-dependencies.sh .
COPY config ./config
COPY tests ./tests
COPY build ./build
COPY scripts ./scripts
COPY cicd-scripts/run-prow-e2e.sh .

RUN npm ci
RUN sh install-dependencies.sh

RUN chmod -R go+w /search-e2e

RUN ["chmod", "+x", "start-tests.sh"]

ENTRYPOINT ["./start-tests.sh"]
