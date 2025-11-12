#!/usr/bin/env bash

# This script is a modified version of community/addons/web/tooling/enable.sh

community=$(cd -- "$(dirname "$0")" &>/dev/null && cd ../../.. && pwd)
tooling="$community/addons/web/tooling"
testRealPath="$(realpath --relative-to=. "$tooling/hooks")"
if [[ $testRealPath == "" ]]; then
    echo "Please install realpath"
    exit 1
fi

enableInDir() {
    cd "$1" || exit

    # Uncomment this to enable the pre-commit hook
    #hooksPath="$(realpath --relative-to=. "$tooling/hooks")"
    #git config core.hooksPath "$hooksPath"

    cp "$tooling/_eslintignore" .eslintignore
    cp "$tooling/_eslintrc.json" .eslintrc.json
    cp "$tooling/_jsconfig.json" jsconfig.json
    cp "$tooling/_package.json" package.json
    if [[ $2 == "copy" ]]; then
        # -i is not supported on mac
        sed "s@addons@$pathFromEnterpriseToCommunity/addons@g" jsconfig.json >tmp.json
        mv tmp.json jsconfig.json
        # copy over node_modules and package-lock to avoid double "npm install"
        cp "$community/package-lock.json" package-lock.json
        cp -a "$community/node_modules" node_modules
    else
        npm install
    fi
    cd - &>/dev/null || exit 1
}

pathToEnterprise="../enterprise"
pathToEnterprise=$(realpath "$community/$pathToEnterprise")
pathFromEnterpriseToCommunity=$(realpath --relative-to="$pathToEnterprise" "$community")

enableInDir "$community"
enableInDir "$pathToEnterprise" copy

cat <<EOF

JS tooling have been added to the roots
Make sure to refresh the eslint and typescript service and configure your IDE so it uses the config files
For VSCode, look inside your .vscode/settings.json file ("editor.defaultFormatter": "dbaeumer.vscode-eslint")

EOF
