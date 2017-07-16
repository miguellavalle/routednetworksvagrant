curl -si -X POST http://192.168.33.12/identity/v3/auth/tokens \
    -H "Content-type: application/json" \
    -d @token-request.json | awk '/X-Subject-Token/ {print $2}'
