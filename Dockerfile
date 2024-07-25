# Copyright (c) 2020 Red Hat, Inc.

FROM registry.ci.openshift.org/stolostron/builder:nodejs20-linux as builder
FROM mikefarah/yq:4.32.2 as yq
FROM cypress/included:10.0.0 AS production

USER root

COPY --from=yq /usr/bin/yq /usr/local/bin/yq
COPY --from=builder /usr/bin/node /usr/bin/node

RUN mkdir -p /search-e2e/cypress_cache
ENV CYPRESS_CACHE_FOLDER=/search-e2e/cypress_cache
WORKDIR /search-e2e
COPY . .

RUN npm ci
RUN sh install-dependencies.sh

RUN chmod -R go+w /search-e2e

RUN ["chmod", "+x", "start-tests.sh"]

ENTRYPOINT ["./start-tests.sh"]
