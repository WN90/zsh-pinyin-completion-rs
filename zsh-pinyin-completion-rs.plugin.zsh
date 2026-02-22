# zsh-pinyin-completion-rs - Pinyin completion for zsh
# Based on https://github.com/AOSC-Dev/bash-pinyin-completion-rs
#
# This plugin enables pinyin-based completion for Chinese filenames.
# For example, typing 'zg' can complete to '中国' (China).
#
# https://github.com/zdharma-continuum/Zsh-100-Commits-Club/blob/master/Zsh-Plugin-Standard.adoc

# Standard zsh plugin detection of the script's path
0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"

# Guard against multiple loads
(( ${+_ZSH_PINYIN_LOADED} )) && return 0
typeset -g _ZSH_PINYIN_LOADED=1

# Plugin directory
typeset -g ZSH_PINYIN_PLUGIN_DIR="${0:h}"

# Add plugin directory to fpath for completion function lookup
if (( fpath[(I)$ZSH_PINYIN_PLUGIN_DIR] == 0 )); then
    fpath+=($ZSH_PINYIN_PLUGIN_DIR)
fi

# Load configuration
source "${ZSH_PINYIN_PLUGIN_DIR}/lib/config.zsh"

# Check if binary exists, try to build if not
_zsh_pinyin_ensure_binary() {
    local bin_path="${ZSH_PINYIN_FILTER_BIN}"

    if [[ -x "$bin_path" ]]; then
        return 0
    fi

    # Check if we need to build from source
    if [[ -f "${ZSH_PINYIN_PLUGIN_DIR}/Cargo.toml" ]]; then
        if command -v cargo &>/dev/null; then
            print -P "%F{yellow}zsh-pinyin-completion-rs: building binary...%f"
            (cd "${ZSH_PINYIN_PLUGIN_DIR}" && cargo build --release 2>/dev/null)
            if [[ -f "${ZSH_PINYIN_PLUGIN_DIR}/target/release/zsh-pinyin-filter" ]]; then
                mkdir -p "${ZSH_PINYIN_PLUGIN_DIR}/bin"
                cp "${ZSH_PINYIN_PLUGIN_DIR}/target/release/zsh-pinyin-filter" "${bin_path}"
                return 0
            fi
        fi
    fi

    return 1
}

# Check binary on load
if ! _zsh_pinyin_ensure_binary; then
    print -P "%F{red}zsh-pinyin-completion-rs: binary not found at ${ZSH_PINYIN_FILTER_BIN}%f"
    print -P "%F{red}Please run: cd ${ZSH_PINYIN_PLUGIN_DIR} && ./install.sh build%f"
    return 1
fi

# Load completion functions
source "${ZSH_PINYIN_PLUGIN_DIR}/lib/pinyin-completion.zsh"

# Store the current completer setting
typeset -ga _zsh_pinyin_orig_completer
_zsh_pinyin_orig_completer=()
zstyle -s ':completion:*' completer _zsh_pinyin_orig_completer 2>/dev/null
if (( ${#_zsh_pinyin_orig_completer} == 0 )); then
    _zsh_pinyin_orig_completer=(_complete _approximate)
fi

# Set up the completer chain with pinyin support
# The pinyin completer will only activate for inputs that look like pinyin
zstyle ':completion:*' completer _zsh_pinyin_complete ${_zsh_pinyin_orig_completer[@]}

# Enable menu selection for pinyin matches
# This allows cycling through candidates with TAB when there's no common prefix
if [[ "${ZSH_PINYIN_MENU_SELECT:-1}" == "1" ]]; then
    zstyle ':completion:*' menu select
    # Auto start menu selection when there are multiple matches
    zstyle ':completion:*:*:pinyin-matches' menu select=2
fi

# Provide a function to toggle pinyin completion
zsh-pinyin-toggle() {
    if [[ "${ZSH_PINYIN_ENABLED:-1}" == "1" ]]; then
        export ZSH_PINYIN_ENABLED=0
        print -P "%F{yellow}Pinyin completion disabled%f"
    else
        export ZSH_PINYIN_ENABLED=1
        print -P "%F{green}Pinyin completion enabled%f"
    fi
}

# Provide a function to show current status
zsh-pinyin-status() {
    local enabled="${ZSH_PINYIN_ENABLED:-1}"
    if [[ "$enabled" == "1" ]]; then
        print -P "Pinyin completion: %F{green}enabled%f"
    else
        print -P "Pinyin completion: %F{yellow}disabled%f"
    fi
    print "Notation mode: ${ZSH_PINYIN_NOTATION:-quanpin}"
    print "Min input length: ${ZSH_PINYIN_MIN_LENGTH:-1}"
    print "Filter binary: ${ZSH_PINYIN_FILTER_BIN}"
}

# Cleanup internal functions
unfunction _zsh_pinyin_ensure_binary 2>/dev/null
