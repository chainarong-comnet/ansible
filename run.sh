#!/bin/bash

# run.sh script to execute Ansible playbooks

docker compose run --rm ansible ansible-playbook  "$@"
