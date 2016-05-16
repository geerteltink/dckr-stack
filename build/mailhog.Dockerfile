# https://github.com/mailhog/MailHog/blob/master/Dockerfile
# https://github.com/diyan/mailhog-docker/blob/master/Dockerfile
FROM alpine:latest

RUN set -x \
  && buildDeps='go git bzr' \
  && apk add --update $buildDeps \
  && GOPATH=/tmp/gocode go get github.com/mailhog/MailHog \
  && mv /tmp/gocode/bin/MailHog /usr/local/bin/ \
  && apk del $buildDeps \
  && rm -rf /var/cache/apk/* /tmp/*

EXPOSE 1025 8025
ENTRYPOINT ["MailHog"]
