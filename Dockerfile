# Copyright (c) 2020 Red Hat, Inc.

FROM mikefarah/yq:3 as builder
FROM cypress/included:5.3.0 as production

USER root

COPY --from=builder /usr/bin/yq /usr/local/bin/yq

COPY package.json .
COPY package-lock.json .
COPY cypress.json .
COPY start-tests.sh .
COPY download-clis.sh .
COPY tests ./tests
RUN npm i

RUN sh download-clis.sh

RUN ["chmod", "+x", "start-tests.sh"]

ENTRYPOINT ["./start-tests.sh"]
