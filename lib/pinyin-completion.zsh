# zsh-pinyin-completion-rs core completion function
# This file provides the _zsh_pinyin_complete completer function

# Check if the input looks like a pinyin pattern (pure lowercase ASCII letters)
_zsh_pinyin_is_pinyin_input() {
    local input="$1"
    # Must be pure lowercase letters with minimum length
    [[ "$input" =~ '^[a-z]+$' && ${#input} -ge ${ZSH_PINYIN_MIN_LENGTH:-1} ]]
}

# Check if a string contains Chinese/CJK characters
_zsh_pinyin_has_chinese() {
    local str="$1"
    # Remove all ASCII printable characters
    # If anything remains, it contains non-ASCII (likely Chinese)
    local non_ascii="${str//[a-zA-Z0-9_\-\.\/\~]/}"
    [[ -n "$non_ascii" ]]
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

    # Determine if we should only show directories based on completion context
    # zsh provides context through:
    # - $curcontext: e.g., "::complete:cd:*"
    # - $service: the command name
    # - $words[1]: the first word on command line
    local dirs_only=0

    # Check curcontext first (most reliable)
    if [[ "$curcontext" == *:cd:* ]] || [[ "$curcontext" == *:pushd:* ]] || \
       [[ "$curcontext" == *:rmdir:* ]] || [[ "$curcontext" == *:chdir:* ]]; then
        dirs_only=1
    # Fallback to service variable
    elif [[ "$service" == "cd" ]] || [[ "$service" == "pushd" ]] || \
         [[ "$service" == "rmdir" ]] || [[ "$service" == "chdir" ]]; then
        dirs_only=1
    # Fallback to checking command line
    elif [[ "${words[1]}" == "cd" ]] || [[ "${words[1]}" == "pushd" ]] || \
         [[ "${words[1]}" == "rmdir" ]] || [[ "${words[1]}" == "chdir" ]]; then
        dirs_only=1
    fi

    # Get all files/directories, including hidden ones
    if [[ -n "$dir_prefix" ]]; then
        candidates=(${glob_dir}*(N))
        candidates+=(${glob_dir}.*(N))
    else
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
        # Check if any match contains Chinese characters
        local has_chinese=0
        local item
        for item in "${filtered[@]}"; do
            if _zsh_pinyin_has_chinese "$item"; then
                has_chinese=1
                break
            fi
        done

        # Build arrays for directories and files with proper suffix handling
        local -a files dirs all_matches displays
        local full_path display_item
        for item in "${filtered[@]}"; do
            full_path="${dir_prefix}${item}"
            if [[ -d "$full_path" ]]; then
                # Directory: add with / suffix, no space after
                dirs+=("${item}/")
                displays+=("${item}/")
            elif (( ! dirs_only )); then
                # File: only add if not in dirs_only mode
                files+=("$item")
                displays+=("$item")
            fi
        done

        # Directories first, then files
        all_matches=("${dirs[@]}" "${files[@]}")

        # Use -S '' to prevent auto-adding space, we handle suffix manually
        _wanted pinyin-matches expl 'pinyin match' \
            compadd -S '' -U -V pinyin-matches -d displays -a all_matches

        if (( has_chinese )); then
            # With Chinese results: first TAB shows list with first item highlighted
            # but command line keeps user input
            # menu:1 means start from first item (default selection)
            compstate[insert]="menu:1"
        else
            # No Chinese results: normal menu selection
            compstate[insert]="menu"
        fi

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
