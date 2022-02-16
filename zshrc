# load custom executable functions
for function in ~/.zsh/functions/*; do
  source $function
done

# extra files in ~/.zsh/configs/pre , ~/.zsh/configs , and ~/.zsh/configs/post
# these are loaded first, second, and third, respectively.
_load_settings() {
  _dir="$1"
  if [ -d "$_dir" ]; then
    if [ -d "$_dir/pre" ]; then
      for config in "$_dir"/pre/**/*~*.zwc(N-.); do
        . $config
      done
    fi

    for config in "$_dir"/**/*(N-.); do
      case "$config" in
        "$_dir"/(pre|post)/*|*.zwc)
          :
          ;;
        *)
          . $config
          ;;
      esac
    done

    if [ -d "$_dir/post" ]; then
      for config in "$_dir"/post/**/*~*.zwc(N-.); do
        . $config
      done
    fi
  fi
}
_load_settings "$HOME/.zsh/configs"

# Local config
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# aliases
[[ -f ~/.aliases ]] && source ~/.aliases

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


shareKeyVaultEnv() {
  cp ~/workspace/dotenv/keyvault.env "$1/sdk/keyvault/keyvault-keys/.env"
  cp ~/workspace/dotenv/keyvault.env "$1/sdk/keyvault/keyvault-secrets/.env"
  cp ~/workspace/dotenv/keyvault.env "$1/sdk/keyvault/keyvault-certificates/.env"
  cp ~/workspace/dotenv/keyvault.env "$1/sdk/keyvault/keyvault-admin/.env"
  echo "done"
}

updateDotEnv() {
  sed -i -e 's/\${env:\([A-Z_]*\)} = /\1=/g' \
  -e 's/[A-Z][A-Z]*_CLIENT_ID=/AZURE_CLIENT_ID=/g' \
  -e 's/[A-Z][A-Z]*_TENANT_ID=/AZURE_TENANT_ID=/g' \
  -e 's/[A-Z][A-Z]*_CLIENT_SECRET=/AZURE_CLIENT_SECRET=/g' "$1"
}

fix_wsl2_interop() {
  for i in $(pstree -np -s $$ | grep -o -E '[0-9]+'); do
    if [[ -e "/run/WSL/${i}_interop" ]]; then
      export WSL_INTEROP=/run/WSL/${i}_interop
    fi
  done
}

gch() {
  result=$(git branch --sort=committerdate --color=always | grep -v '/HEAD\s' |
    fzf --height 50% --border --ansi --tac --preview-window right:70% \
    --preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1) | head -'$LINES |
    sed 's/^..//' | cut -d' ' -f1)

  if [[ $result != "" ]]; then
    if [[ $result == remotes/* ]]; then
      git checkout --track $(echo $result | sed 's#remotes/##')
    else
      git checkout "$result"
    fi
  fi
}