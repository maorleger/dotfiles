#!/bin/bash

set -e

echo 'starting dotfiles bootstrap'
# Install rcm
echo 'installing rcm'
sudo apt update
sudo apt install rcm

echo 'starting dotfiles bootstrap'
env RCRC="$(pwd)"/rcrc rcup
