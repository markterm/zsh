function () { # precompile
    local A
    A=~/.oh-my-zsh/custom/auto-fu/auto-fu.zsh
    [[ -e "${A:r}.zwc" ]] && [[ "$A" -ot "${A:r}.zwc" ]] ||
    zsh -c "source $A; auto-fu-zcompile $A ${A:h}" >/dev/null 2>&1
}

source $HOME/.oh-my-zsh/custom/auto-fu/auto-fu.zsh
zle-line-init () {auto-fu-init;}; zle -N zle-line-init

function afu+cancel () {
    afu-clearing-maybe
    ((afu_in_p == 1)) && { afu_in_p=0; BUFFER="$buffer_cur"; }
}
zle -N afu+cancel
function bindkey-advice-before () {
    local key="$1"
    local advice="$2"
    local widget="$3"
    [[ -z "$widget" ]] && {
        local -a bind
        bind=(`bindkey -M main "$key"`)
        widget=$bind[2]
    }
    local fun="$advice"
    if [[ "$widget" != "undefined-key" ]]; then
        local code=${"$(<=(cat <<"EOT"
            function $advice-$widget () {
                zle $advice
                zle $widget
            }
            fun="$advice-$widget"
EOT
        ))"}
        eval "${${${code//\$widget/$widget}//\$key/$key}//\$advice/$advice}"
    fi
    zle -N "$fun"
    bindkey -M afu "$key" "$fun"
}
#bindkey-advice-before "^G" afu+cancel
bindkey-advice-before "^[" afu+cancel
bindkey-advice-before "^M" afu+cancel afu+accept-line
bindkey -M menuselect "^M" .accept-line

# delete unambiguous prefix when accepting line
function afu+delete-unambiguous-prefix () {
    afu-clearing-maybe
    local buf; buf="$BUFFER"
    local bufc; bufc="$buffer_cur"
    [[ -z "$cursor_new" ]] && cursor_new=-1
    [[ "$buf[$cursor_new]" == ' ' ]] && return
    [[ "$buf[$cursor_new]" == '/' ]] && return
    ((afu_in_p == 1)) && [[ "$buf" != "$bufc" ]] && {
        # there are more than one completion candidates
        zle afu+complete-word
        [[ "$buf" == "$BUFFER" ]] && {
            # the completion suffix was an unambiguous prefix
            afu_in_p=0; buf="$bufc"
        }
        BUFFER="$buf"
        buffer_cur="$bufc"
    }
}
zle -N afu+delete-unambiguous-prefix
function afu-ad-delete-unambiguous-prefix () {
    local afufun="$1"
    local code; code=$functions[$afufun]
    eval "function $afufun () { zle afu+delete-unambiguous-prefix; $code }"
}
afu-ad-delete-unambiguous-prefix afu+accept-line
afu-ad-delete-unambiguous-prefix afu+accept-line-and-down-history
afu-ad-delete-unambiguous-prefix afu+accept-and-hold


# yay for multiple-cursor.el

zstyle ':completion:*' completer _oldlist _complete _expand
#zle -N zle-keymap-select auto-fu-zle-keymap-select

zstyle ':auto-fu:highlight' input bold
zstyle ':auto-fu:highlight' completion fg=white,dim
zstyle ':auto-fu:highlight' completion/one fg=blue,dim
zstyle ':auto-fu:var' postdisplay ''

zstyle ':auto-fu:var' autoable-function/skipwords "*\**"
zstyle ':auto-fu:var' autoable-function/skiplines '*rake *' 'gem *' 'git log *' 'git commit *' 'scp *'  'svn commit *'

setopt nosharehistory
