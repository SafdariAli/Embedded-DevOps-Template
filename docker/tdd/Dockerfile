FROM ruby:3.4.10-alpine3.24

ARG CEEDLING_VERSION=1.1.1

RUN apk add --no-cache \
    gcc \
    musl-dev \
    make \
    binutils

RUN gem install ceedling \
    -v "${CEEDLING_VERSION}" \
    --no-document

WORKDIR /workspace

CMD ["ceedling", "test:all"]