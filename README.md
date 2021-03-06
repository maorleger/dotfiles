Mostly used when terraforming an EC2 instance for development.

I lean heavily on [Braintree's vim config](https://github.com/braintreeps/vim_dotfiles) so this contains only my local overrides

## Prerequisites

1. [zsh](https://github.com/robbyrussell/oh-my-zsh/wiki/Installing-ZSH)
1. [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)
1. [tmux](https://github.com/tmux/tmux)
1. [diff-so-fancy](https://github.com/so-fancy/diff-so-fancy) for git diffs
1. [rcm](https://github.com/thoughtbot/rcm#installation)
1. [Braintree's vim dotfiles](https://github.com/braintreeps/vim_dotfiles)

## Installation

```
# After all of the above have been installed
git clone https://github.com/maorleger/dotfiles $HOME/.dotfiles
env RCRC=$HOME/.dotfiles/rcrc rcup
~/.vim/activate.sh
```

## Post installation

```
git config --global user.name "Your name"
git config --global user.email "Your email"
```

## Uninstall

```
rcdn
```
