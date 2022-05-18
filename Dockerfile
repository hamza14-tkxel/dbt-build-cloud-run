#https://snyk.io/blog/10-best-practices-to-containerize-nodejs-web-applications-with-docker/

# --------------> The build image
FROM node:16-alpine3.11@sha256:baa9d25aa3ad4d9970d2553a12199b99f9fc646d0158d56e460d3fdce794b541 AS build
WORKDIR /usr/src/app
COPY package*.json /usr/src/app/
COPY .npmrc /usr/src/app/
#COPY nathanwade-tf-admin.json /usr/src/
#RUN export GOOGLE_APPLICATION_CREDENTIALS="/usr/src/nathanwade-tf-admin.json"

RUN npm install @google-cloud/dataflow
RUN npm i @google-cloud/secret-manager
RUN npm i

#RUN --mount=type=secret,mode=0644,id=npmrc,target=/usr/src/app/.npmrc npm i

# --------------> The production image


FROM google/cloud-sdk:alpine

RUN apk update \
    && apk add dumb-init \
    && apk add curl \
    && apk add --no-cache git \
    && apk add --update nodejs npm




RUN apk --no-cache upgrade apk-tools \
    && apk add --no-cache python3 py3-pip curl \
    && apk add --no-cache python3-dev \
    && pip install --upgrade pip setuptools wheel \
    && pip3 install maturin \
    && pip install dbt-bigquery \
    && pip install markupsafe==2.0.1


RUN adduser \
    --disabled-password \
    node
RUN git clone -b master https://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:x-oauth-basic@github.com/sproutward-dbt-clients/client-hanky-poc.git /usr/src/app/self-service-dbt-build && cd /usr/src/app/self-service-dbt-build && git checkout e440afd5a3c9939de2bc297dd1783f0a878a30c0
RUN mkdir -p /usr/src/app
RUN chown -R node:node /usr/src/app
USER node
WORKDIR /usr/src/app
COPY --chown=node:node --from=build /usr/src/app/node_modules /usr/src/app/node_modules
COPY --chown=node:node . /usr/src/app
CMD ["dumb-init", "node", "src/index.js"]