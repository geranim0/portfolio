FROM klakegg/hugo:0.82.0-alpine

RUN apk update; \
    apk add git