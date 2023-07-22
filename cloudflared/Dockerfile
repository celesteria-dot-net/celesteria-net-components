FROM alpine as cloudflared-builder

USER root

# install dependencies
RUN apk --update --no-cache add \
    bash \
    build-base \
    go \
    gcc \
    git \
  && rm -rf /tmp/* /var/cache/apk/*

RUN git clone \
    --depth 1 \
    --branch 2023.7.1 \
    https://github.com/cloudflare/cloudflared /go/src/github.com/cloudflare/cloudflared

WORKDIR /go/src/github.com/cloudflare/cloudflared

ENV GO111MODULE=on
ENV CGO_ENABLED=0
RUN go build -v -mod vendor \
    -ldflags \
    "-w -s -X 'main.Version=2023.7.1' -X 'main.BuildTime=$(date -u +'%Y-%m-%dT%H:%M:%SZ')'" \
    github.com/cloudflare/cloudflared/cmd/cloudflared

FROM alpine
COPY --from=cloudflared-builder /go/src/github.com/cloudflare/cloudflared/cloudflared /usr/local/bin/cloudflared

# install yq (see https://github.com/mikefarah/yq/issues/190#issuecomment-692890953)
RUN apk --update --no-cache add \
    yq --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community \
  && rm -rf /tmp/* /var/cache/apk/*

RUN mkdir -p /tmp

COPY ./entrypoint.sh /tmp/entrypoint.sh

ENTRYPOINT [ "/tmp/entrypoint.sh" ]
