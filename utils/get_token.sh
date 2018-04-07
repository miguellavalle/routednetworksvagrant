TOKEN=$(curl -si -X POST http://localhost/identity/v3/auth/tokens \
    -H "Content-type: application/json" \
    -d '{
            "auth": {
                "identity": {
                    "methods": [
                        "password"
                    ],
                    "password": {
                        "user": {
                            "domain": {
                                "name": "Default"
                            },
                            "name": "admin",
                            "password": "devstack"
                        }
                    }
                },
                "scope": {
                    "project": {
                        "domain": {
                            "name": "Default"
                        },
                        "name": "admin"
                    }
                }
            }
        }' \
    | awk '/X-Subject-Token/ {print $2}')
