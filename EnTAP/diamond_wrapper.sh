#!/bin/bash

if [[ "$1" == "--version" ]]; then
  echo "diamond version 2.1.8"
  exit 0
else
  /software/el9/apps/diamond/2.1.8/diamond "$@"
fi
