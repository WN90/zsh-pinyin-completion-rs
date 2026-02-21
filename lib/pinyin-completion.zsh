# zsh-pinyin-completion-rs core completion function
# This file provides the _zsh_pinyin_complete completer function

# Check if the input looks like a pinyin pattern (pure lowercase ASCII letters)
_zsh_pinyin_is_pinyin_input() {
    local input="$1"
    # Must be pure lowercase letters with minimum length
    [[ "$input" =~ '^[a-z]+$' && ${#input} -ge ${ZSH_PINYIN_MIN_LENGTH:-1} ]]
}

# Main pinyin completion function
_zsh_pinyin_complete() {
    # Check if pinyin completion is enabled
    [[ "${ZSH_PINYIN_ENABLED:-1}" == "1" ]] || return 1

    # Get the current word being completed
    local word="${PREFIX}${SUFFIX}"

    # Skip if input doesn't look like pinyin
    _zsh_pinyin_is_pinyin_input "$word" || return 1

    # Check if the binary exists
    if [[ ! -x "${ZSH_PINYIN_FILTER_BIN}" ]]; then
        return 1
    fi

    # Get the directory prefix for relative path completion
    local dir_prefix=""
    local word_base="$word"
    if [[ "$PREFIX" == */* ]]; then
        dir_prefix="${PREFIX%/*}/"
        word_base="${PREFIX##*/}"
    fi

    # Build the file list from the appropriate directory
    local -a candidates
    local glob_dir="${dir_prefix:-.}"

    # Get all files/directories, including hidden ones if needed
    if [[ -n "$dir_prefix" ]]; then
        # For paths with directory prefix, list files in that directory
        candidates=(${glob_dir}*(N))
        # Also include hidden files if the word starts with a letter that could match hidden files
        candidates+=(${glob_dir}.*(N))
    else
        # For current directory
        candidates=(*(N) .*(N))
    fi

    # No candidates found
    (( ${#candidates} > 0 )) || return 1

    # Filter candidates through the pinyin matcher
    local -a filtered
    local candidate

    # Export notation for the binary
    export ZSH_PINYIN_NOTATION

    # Use the binary to filter candidates
    filtered=(${(f)"$(print -l -- $candidates | "${ZSH_PINYIN_FILTER_BIN}" "$word_base" 2>/dev/null)"})

    # If we have matches, add them to completion
    if (( ${#filtered} > 0 )); then
        # Add matches with appropriate options
        # -U means don't do any special character handling
        # -a means the matches are in an array
        compadd -U -a filtered
        return 0
    fi

    return 1
}

# Helper function to list all pinyin completion matches (for debugging)
_zsh_pinyin_list_matches() {
    local word="$1"
    local -a candidates
    candidates=(*(N) .*(N))

    print -l -- $candidates | "${ZSH_PINYIN_FILTER_BIN}" "$word"
}
