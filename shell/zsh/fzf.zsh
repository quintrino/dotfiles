# Setup fzf
# ---------
if ! command -v fzf 1> /dev/null; then
  echo 'WARNING: fzf not found, maybe check brew installed it?'
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/usr/local/opt/fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "/usr/local/opt/fzf/shell/key-bindings.zsh"

bindkey '^F' fzf-file-widget
