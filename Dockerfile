FROM docker:stable-dind
MAINTAINER Pavol Noha <pavol.noha@gmail.com>

RUN apk add --update git && \
    rm -rf /var/cache/apk/*

WORKDIR /
ADD . /

ARG tag
ENV VERSION=$tag

CMD ["sh", "install.sh"]

