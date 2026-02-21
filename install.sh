#!/usr/bin/env bash
#
# Installation script for zsh-pinyin-completion-rs
# Supports: Oh My Zsh, Zinit, Antigen, and manual installation
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_NAME="zsh-pinyin-completion-rs"
VERSION="${VERSION:-0.1.0}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Detect system architecture
detect_arch() {
    local arch=$(uname -m)
    case $arch in
        x86_64|amd64) echo "x86_64" ;;
        aarch64|arm64) echo "aarch64" ;;
        armv7l|armhf) echo "armv7" ;;
        *) echo "$arch" ;;
    esac
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*) echo "linux" ;;
        Darwin*) echo "macos" ;;
        *) echo "unknown" ;;
    esac
}

# Download prebuilt binary
download_binary() {
    local os=$(detect_os)
    local arch=$(detect_arch)
    local bin_dir="${SCRIPT_DIR}/bin"
    local bin_name="zsh-pinyin-filter"
    local download_url="https://github.com/YOUR_USERNAME/${PLUGIN_NAME}/releases/download/v${VERSION}/${bin_name}-${os}-${arch}"

    mkdir -p "$bin_dir"

    info "Downloading prebuilt binary for ${os}-${arch}..."

    if command -v curl &>/dev/null; then
        if curl -fsSL "$download_url" -o "${bin_dir}/${bin_name}.tmp"; then
            mv "${bin_dir}/${bin_name}.tmp" "${bin_dir}/${bin_name}"
            chmod +x "${bin_dir}/${bin_name}"
            success "Binary downloaded successfully"
            return 0
        fi
    elif command -v wget &>/dev/null; then
        if wget -q "$download_url" -O "${bin_dir}/${bin_name}.tmp"; then
            mv "${bin_dir}/${bin_name}.tmp" "${bin_dir}/${bin_name}"
            chmod +x "${bin_dir}/${bin_name}"
            success "Binary downloaded successfully"
            return 0
        fi
    fi

    warn "Failed to download prebuilt binary"
    return 1
}

# Build from source
build_from_source() {
    info "Building from source..."

    if ! command -v cargo &>/dev/null; then
        error "Rust/Cargo not found. Please install Rust: https://rustup.rs/"
    fi

    cd "$SCRIPT_DIR"
    cargo build --release

    local bin_dir="${SCRIPT_DIR}/bin"
    mkdir -p "$bin_dir"
    cp target/release/zsh-pinyin-filter "${bin_dir}/"

    success "Binary built successfully"
}

# Ensure binary is available
ensure_binary() {
    local bin_path="${SCRIPT_DIR}/bin/zsh-pinyin-filter"

    if [[ -x "$bin_path" ]]; then
        info "Binary already exists at $bin_path"
        return 0
    fi

    # Try prebuilt binary first, then build from source
    if ! download_binary; then
        build_from_source
    fi
}

# Install for Oh My Zsh
install_omz() {
    local omz_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    local plugin_dir="${omz_custom}/plugins/${PLUGIN_NAME}"

    info "Installing for Oh My Zsh..."

    if [[ -d "$plugin_dir" ]]; then
        warn "Plugin directory already exists. Updating..."
        rm -rf "$plugin_dir"
    fi

    mkdir -p "$plugin_dir"
    cp -r "$SCRIPT_DIR"/* "$plugin_dir/"

    # Ensure binary is available
    cd "$plugin_dir"
    ensure_binary

    success "Installed to $plugin_dir"
    echo ""
    echo "Add the following to your ~/.zshrc:"
    echo "  plugins=(... ${PLUGIN_NAME})"
    echo ""
    echo "Then restart zsh or run: source ~/.zshrc"
}

# Install for Zinit
install_zinit() {
    info "Installing for Zinit..."
    ensure_binary

    echo ""
    echo "Add the following to your ~/.zshrc:"
    echo "  zinit light YOUR_USERNAME/${PLUGIN_NAME}"
    echo ""
    echo "Then restart zsh or run: zinit load YOUR_USERNAME/${PLUGIN_NAME}"
}

# Install for Antigen
install_antigen() {
    info "Installing for Antigen..."
    ensure_binary

    echo ""
    echo "Add the following to your ~/.zshrc:"
    echo "  antigen bundle YOUR_USERNAME/${PLUGIN_NAME}"
    echo ""
    echo "Then restart zsh or run: antigen apply"
}

# Manual installation
install_manual() {
    local install_dir="${1:-$HOME/.local/share/${PLUGIN_NAME}}"

    info "Installing manually to $install_dir..."

    mkdir -p "$install_dir"
    cp -r "$SCRIPT_DIR"/* "$install_dir/"

    cd "$install_dir"
    ensure_binary

    success "Installed to $install_dir"
    echo ""
    echo "Add the following to your ~/.zshrc:"
    echo "  source ${install_dir}/${PLUGIN_NAME}.plugin.zsh"
    echo ""
    echo "Then restart zsh or run: source ~/.zshrc"
}

# Show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS] [COMMAND]

Commands:
  omz         Install for Oh My Zsh
  zinit       Show Zinit installation instructions
  antigen     Show Antigen installation instructions
  manual      Manual installation (default: ~/.local/share/${PLUGIN_NAME})
  build       Build binary from source only
  help        Show this help message

Options:
  -d, --dir DIR    Installation directory (for manual install)
  -v, --version    Version to download (default: ${VERSION})

Examples:
  $0 omz                    # Install for Oh My Zsh
  $0 manual -d ~/my-plugins # Manual install to custom directory
  $0 build                  # Just build the binary
EOF
}

# Main
main() {
    local command="${1:-}"
    local install_dir=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dir)
                install_dir="$2"
                shift 2
                ;;
            -v|--version)
                VERSION="$2"
                shift 2
                ;;
            omz|zinit|antigen|manual|build|help)
                command="$1"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    case "$command" in
        omz)
            install_omz
            ;;
        zinit)
            install_zinit
            ;;
        antigen)
            install_antigen
            ;;
        manual)
            install_manual "$install_dir"
            ;;
        build)
            ensure_binary
            success "Binary ready at ${SCRIPT_DIR}/bin/zsh-pinyin-filter"
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            usage
            ;;
    esac
}

main "$@"
