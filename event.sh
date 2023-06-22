#!/bin/bash
curl -v \
-H 'X-GitHub-Event: push' \
-H 'X-Hub-Signature: sha1=723f0cf1dae8940a2d28d81a4f9be3608f36a121' \
-H 'Content-Type: application/json' \
-d @payload.json \
http://localhost:8080/hooks
