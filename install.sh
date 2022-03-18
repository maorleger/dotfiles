#!/usr/bin/env bash

apt-get update
apt-get install -y rcm


chsh -s $(which zsh) $USERNAME

env RCRC=$HOME/dotfiles/rcrc rcup -t work