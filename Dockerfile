FROM alpine:3.22
ARG TARGETARCH
RUN apk add --no-cache ca-certificates busybox-extras curl unzip && \
    A="${TARGETARCH:-amd64}"; case "$A" in arm64) X=arm64-v8a;; *) A=amd64; X=64;; esac; \
    curl -fsSL -o /tmp/x.zip "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-$X.zip" && \
    unzip -o /tmp/x.zip xray -d /usr/local/bin && \
    curl -fsSL -o /tmp/n.zip "https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_$A.zip" && \
    unzip -o /tmp/n.zip -d /usr/local/bin && \
    chmod +x /usr/local/bin/xray /usr/local/bin/nezha-agent && \
    rm -f /tmp/*.zip && apk del curl unzip
WORKDIR /app
COPY www /app/www
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh
EXPOSE 8080
CMD ["/app/start.sh"]
