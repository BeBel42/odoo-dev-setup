#!/usr/bin/env bash
# get-help.sh - outputs the ./o script help

cd "$(dirname "$0")/../../../.." || exit 1
./o --help
