curl -s -X DELETE http://localhost:9696/v2.0/ports/c8c658e7-29f4-425e-96de-f819d09f9431/bindings/compute1 \
    -H "Content-type: application/json" \
    -H "X-Auth-Token: $TOKEN" | jq
