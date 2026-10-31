FROM alpine:3.22
RUN apk add --no-cache ca-certificates busybox-extras curl unzip && \
    mkdir -p /opt/bin /tmp/z && \
    big() { b=""; m=0; for f in "$1"/*; do [ -f "$f" ] || continue; s=$(wc -c <"$f"); [ "$s" -gt "$m" ] && { m=$s; b="$f"; }; done; echo "$b"; }; \
    get() { curl -fsSL -o /tmp/z/a.zip "$(echo "$1" | base64 -d)"; rm -rf /tmp/z/x; mkdir -p /tmp/z/x; unzip -o /tmp/z/a.zip -d /tmp/z/x >/dev/null; mv "$(big /tmp/z/x)" "$2"; chmod +x "$2"; }; \
    get aHR0cHM6Ly9naXRodWIuY29tL1hUTFMvWHJheS1jb3JlL3JlbGVhc2VzL2xhdGVzdC9kb3dubG9hZC9YcmF5LWxpbnV4LTY0LnppcA== /opt/bin/web.amd64 && \
    get aHR0cHM6Ly9naXRodWIuY29tL1hUTFMvWHJheS1jb3JlL3JlbGVhc2VzL2xhdGVzdC9kb3dubG9hZC9YcmF5LWxpbnV4LWFybTY0LXY4YS56aXA= /opt/bin/web.arm64 && \
    get aHR0cHM6Ly9naXRodWIuY29tL25lemhhaHEvYWdlbnQvcmVsZWFzZXMvbGF0ZXN0L2Rvd25sb2FkL25lemhhLWFnZW50X2xpbnV4X2FtZDY0LnppcA== /opt/bin/mon.amd64 && \
    get aHR0cHM6Ly9naXRodWIuY29tL25lemhhaHEvYWdlbnQvcmVsZWFzZXMvbGF0ZXN0L2Rvd25sb2FkL25lemhhLWFnZW50X2xpbnV4X2FybTY0LnppcA== /opt/bin/mon.arm64 && \
    rm -rf /tmp/z && apk del curl unzip
WORKDIR /app
COPY www /app/www
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh
EXPOSE 8080
CMD ["/app/start.sh"]
