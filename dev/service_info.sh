#!/bin/bash
printf "Tasks:\n"
curl --unix-socket /var/run/docker.sock -sgG -X GET http:/v1.24/tasks?filters="{\"service\":[\"$1\"]}" | jq -r 'sort_by(.CreatedAt) | .[].Status | "\(.Timestamp) - \(.State) - \(.Err) "'
printf "\nStatus: "
curl --unix-socket /var/run/docker.sock -sgG -X GET http:/v1.24/tasks?filters="{\"service\":[\"$1\"]}" | jq -r 'sort_by(.CreatedAt) | .[-1].Status.State'