#!/bin/bash

set -e

echo 'starting dotfiles bootstrap'

# Install rcm
echo 'installing rcm'
sudo apt update
sudo apt install rcm -y

BASEDIR=$(realpath $(dirname "$0"))

echo "rcrc located in $BASEDIR"
env RCRC="$BASEDIR"/rcrc rcup -v -f -d "$BASEDIR" -d "$BASEDIR"/dotfiles-local