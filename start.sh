#!/bin/sh
PORT="${PORT:-8080}"
UUID="${UUID:-fd390ec0-a676-48a8-860d-cfd3132c5e8e}"
DOMAIN="${DOMAIN:-${SUGA_PUBLIC_HOSTNAME:-}}"
NAME="${NAME:-suga}"
NEZHA_SERVER="${NEZHA_SERVER:-mnz.9943826.xyz:8008}"
NEZHA_KEY="${NEZHA_KEY:-v2IlOy13fMW0fOHMTuKPSeCliG1TGF2S}"
SUB_PATH="${SUB_PATH:-sub}"
W=/tmp/run; mkdir -p "$W"; rm -rf "$W/www"; cp -r /app/www "$W/www"

cat > "$W/x.json" <<J
{"log":{"loglevel":"none"},
"inbounds":[
{"port":$PORT,"listen":"0.0.0.0","protocol":"vless","settings":{"clients":[{"id":"$UUID"}],"decryption":"none","fallbacks":[{"dest":8081},{"path":"/vless-argo","dest":3002},{"path":"/vmess-argo","dest":3003},{"path":"/trojan-argo","dest":3004}]},"streamSettings":{"network":"tcp"}},
{"port":3002,"listen":"127.0.0.1","protocol":"vless","settings":{"clients":[{"id":"$UUID"}],"decryption":"none"},"streamSettings":{"network":"ws","wsSettings":{"path":"/vless-argo"}}},
{"port":3003,"listen":"127.0.0.1","protocol":"vmess","settings":{"clients":[{"id":"$UUID","alterId":0}]},"streamSettings":{"network":"ws","wsSettings":{"path":"/vmess-argo"}}},
{"port":3004,"listen":"127.0.0.1","protocol":"trojan","settings":{"clients":[{"password":"$UUID"}]},"streamSettings":{"network":"ws","wsSettings":{"path":"/trojan-argo"}}}
],
"outbounds":[{"protocol":"freedom","tag":"direct"}]}
J

P="${NEZHA_SERVER##*:}"; TLS=false
case "$P" in 443|8443|2096|2087|2083|2053) TLS=true;; esac
cat > "$W/nz.yaml" <<Y
client_secret: $NEZHA_KEY
debug: false
disable_auto_update: true
disable_command_execute: false
disable_force_update: true
insecure_tls: true
report_delay: 4
server: $NEZHA_SERVER
skip_connection_count: true
skip_procs_count: true
tls: $TLS
uuid: $UUID
Y

if [ -n "$DOMAIN" ]; then
  VM=$(printf '{"v":"2","ps":"%s","add":"%s","port":"443","id":"%s","aid":"0","scy":"auto","net":"ws","type":"none","host":"%s","path":"/vmess-argo?ed=2560","tls":"tls","sni":"%s","fp":"firefox"}' "$NAME" "$DOMAIN" "$UUID" "$DOMAIN" "$DOMAIN" | base64 -w 0)
  printf 'vless://%s@%s:443?encryption=none&security=tls&sni=%s&fp=firefox&type=ws&host=%s&path=%%2Fvless-argo%%3Fed%%3D2560#%s\nvmess://%s\ntrojan://%s@%s:443?security=tls&sni=%s&fp=firefox&type=ws&host=%s&path=%%2Ftrojan-argo%%3Fed%%3D2560#%s\n' \
    "$UUID" "$DOMAIN" "$DOMAIN" "$DOMAIN" "$NAME" "$VM" "$UUID" "$DOMAIN" "$DOMAIN" "$DOMAIN" "$NAME" | base64 -w 0 > "$W/www/$SUB_PATH"
fi

export GOMAXPROCS=1
( while true; do nice -n 19 nezha-agent -c "$W/nz.yaml" >/dev/null 2>&1; sleep 30; done ) &
( while true; do busybox-extras httpd -f -p 127.0.0.1:8081 -h "$W/www"; sleep 3; done ) &
echo "started on $PORT"
while true; do xray run -c "$W/x.json"; echo "xray exited"; sleep 3; done
