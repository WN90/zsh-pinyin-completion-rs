# zsh-pinyin-completion-rs configuration
# This file sets default values for configuration options

# Path to the pinyin filter binary
# Can be overridden by setting ZSH_PINYIN_FILTER_BIN before loading the plugin
# Uses ZSH_PINYIN_PLUGIN_DIR set by the main plugin file
: ${ZSH_PINYIN_FILTER_BIN:="${ZSH_PINYIN_PLUGIN_DIR}/bin/zsh-pinyin-filter"}

# Pinyin notation mode
# Supported values: quanpin, xiaohe, ms, abc, jiajia, thunisoft, zrm
# Can also combine with comma: "quanpin,xiaohe"
: ${ZSH_PINYIN_NOTATION:="quanpin"}

# Minimum input length to trigger pinyin completion
# Shorter inputs will fall back to normal completion
: ${ZSH_PINYIN_MIN_LENGTH:=1}

# Whether to enable pinyin completion (can be used to temporarily disable)
: ${ZSH_PINYIN_ENABLED:=1}
