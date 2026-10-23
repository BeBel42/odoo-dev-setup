#!/usr/bin/env bash

# colorized message helpers, meant to be sourced by other scripts

print_error() {
    echo -e "\033[1;31mError\033[0m: $*" 1>&2
}

print_warning() {
    echo -e "\033[1;33mWarning\033[0m: $*" 1>&2
}
