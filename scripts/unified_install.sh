#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DEFAULT_DOTFILES_URL="${DEFAULT_DOTFILES_URL:-https://gitlab.com/cbwinslow/dotfiles.git}"
readonly HOME_DIR="${HOME}"
readonly CANONICAL_BASHD_DIR="${HOME_DIR}/bash.d"
readonly LEGACY_BASHD_DIR="${HOME_DIR}/.bash.d"
readonly BASHD_SYMLINK="${HOME_DIR}/bashd"

print_header() {
    cat << 'EOF'
Unified Installer: yadm + dotfiles + bash.d
================================================
EOF
}

info() {
    echo "[info] $*"
}

warn() {
    echo "[warn] $*"
}

error() {
    echo "[error] $*" >&2
}

ask_choice() {
    local prompt="$1"
    shift
    local options=("$@")
    local selection=""

    while true; do
        echo ""
        echo "$prompt"
        for i in "${!options[@]}"; do
            printf "  %d) %s\n" "$((i + 1))" "${options[$i]}"
        done
        read -r -p "Select [1-${#options[@]}]: " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && ((selection >= 1 && selection <= ${#options[@]})); then
            echo "${options[$((selection - 1))]}"
            return 0
        fi
        echo "Invalid selection. Try again."
    done
}

ask_yes_no_idk() {
    local prompt="$1"
    local choice
    choice=$(ask_choice "$prompt" "Yes" "No" "I don't know")
    case "$choice" in
        "Yes") echo "yes" ;;
        "No") echo "no" ;;
        *) echo "idk" ;;
    esac
}

scan_candidates() {
    local label="$1"
    local pattern="$2"
    local maxdepth="${3:-3}"
    local results=()
    mapfile -t results < <(find "$HOME_DIR" -maxdepth "$maxdepth" -type d -name "$pattern" 2>/dev/null | sort)
    if [[ ${#results[@]} -eq 0 ]]; then
        printf "%s: none\n" "$label"
    else
        printf "%s:\n" "$label"
        printf "  %s\n" "${results[@]}"
    fi
}

scan_state() {
    info "Scanning existing setup..."

    YADM_INSTALLED="no"
    YADM_REPO_PRESENT="no"
    YADM_REMOTE=""

    if command -v yadm >/dev/null 2>&1; then
        YADM_INSTALLED="yes"
        if yadm status >/dev/null 2>&1; then
            YADM_REPO_PRESENT="yes"
            YADM_REMOTE="$(yadm config --get remote.origin.url 2>/dev/null || true)"
        fi
    fi

    mapfile -t DOTFILES_DIRS < <(find "$HOME_DIR" -maxdepth 3 -type d \( -name "dotfiles" -o -name ".dotfiles" \) 2>/dev/null | sort)
    mapfile -t BASHD_DIRS < <(find "$HOME_DIR" -maxdepth 4 -type d \( -name "bash.d" -o -name ".bash.d" \) 2>/dev/null | sort)

    BASHD_SYMLINK_TARGET=""
    if [[ -L "$BASHD_SYMLINK" ]]; then
        BASHD_SYMLINK_TARGET="$(readlink "$BASHD_SYMLINK" 2>/dev/null || true)"
    fi

    YADM_CONFIG_DIR="${HOME_DIR}/.config/yadm"
    YADM_REPO_DIR="${HOME_DIR}/.local/share/yadm/repo.git"
}

render_report() {
    echo ""
    echo "Current state summary"
    echo "---------------------"
    echo "yadm installed: $YADM_INSTALLED"
    echo "yadm repo present: $YADM_REPO_PRESENT"
    if [[ -n "$YADM_REMOTE" ]]; then
        echo "yadm remote: $YADM_REMOTE"
    fi
    echo "canonical bash.d: $CANONICAL_BASHD_DIR"
    echo "legacy bash.d: $LEGACY_BASHD_DIR"
    if [[ -L "$BASHD_SYMLINK" ]]; then
        echo "bashd symlink: $BASHD_SYMLINK -> $BASHD_SYMLINK_TARGET"
    else
        echo "bashd symlink: not present"
    fi
    if [[ -d "$YADM_CONFIG_DIR" ]]; then
        echo "yadm config dir: $YADM_CONFIG_DIR"
    else
        echo "yadm config dir: not found"
    fi
    if [[ -d "$YADM_REPO_DIR" ]]; then
        echo "yadm repo dir: $YADM_REPO_DIR"
    else
        echo "yadm repo dir: not found"
    fi
    echo ""
    scan_candidates "dotfiles candidates" "dotfiles" 3
    scan_candidates "dotfiles candidates" ".dotfiles" 3
    scan_candidates "bash.d candidates" "bash.d" 4
    scan_candidates "bash.d candidates" ".bash.d" 4
    echo ""
}

install_yadm() {
    local install_choice
    install_choice=$(ask_choice "Install yadm now?" \
        "Use package manager (apt/dnf/brew/pacman)" \
        "Download yadm to /usr/local/bin via curl" \
        "Skip" \
        "I don't know")

    case "$install_choice" in
        "Use package manager (apt/dnf/brew/pacman)")
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update
                sudo apt-get install -y yadm
            elif command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y yadm
            elif command -v pacman >/dev/null 2>&1; then
                sudo pacman -Sy --noconfirm yadm
            elif command -v brew >/dev/null 2>&1; then
                brew install yadm
            else
                warn "No supported package manager found."
            fi
            ;;
        "Download yadm to /usr/local/bin via curl")
            sudo curl -fLo /usr/local/bin/yadm https://github.com/TheLocehiliosan/yadm/raw/master/yadm
            sudo chmod +x /usr/local/bin/yadm
            ;;
        "Skip"|"I don't know")
            warn "Skipping yadm installation."
            ;;
    esac
}

ensure_yadm() {
    if command -v yadm >/dev/null 2>&1; then
        info "yadm is installed."
        return 0
    fi

    install_yadm
    if command -v yadm >/dev/null 2>&1; then
        info "yadm installed successfully."
    else
        warn "yadm is still not available."
    fi
}

prompt_dotfiles_url() {
    local choice
    choice=$(ask_choice "Select dotfiles repository URL" \
        "Use default (${DEFAULT_DOTFILES_URL})" \
        "Enter a custom URL" \
        "Skip" \
        "I don't know")

    case "$choice" in
        "Use default (${DEFAULT_DOTFILES_URL})")
            echo "$DEFAULT_DOTFILES_URL"
            ;;
        "Enter a custom URL")
            read -r -p "Dotfiles repo URL: " custom_url
            echo "$custom_url"
            ;;
        *)
            echo ""
            ;;
    esac
}

ensure_yadm_repo() {
    if ! command -v yadm >/dev/null 2>&1; then
        warn "yadm is not installed; cannot manage dotfiles repo."
        return 1
    fi

    if yadm status >/dev/null 2>&1; then
        info "yadm repo already initialized."
        return 0
    fi

    local repo_url=""
    repo_url="$(prompt_dotfiles_url)"
    if [[ -z "$repo_url" ]]; then
        warn "No dotfiles repository URL provided."
        return 1
    fi

    local clone_mode
    clone_mode=$(ask_choice "yadm clone mode" \
        "Normal clone (fail on conflicts)" \
        "Force clone (overwrite conflicts)" \
        "Skip" \
        "I don't know")

    case "$clone_mode" in
        "Normal clone (fail on conflicts)")
            yadm clone "$repo_url"
            ;;
        "Force clone (overwrite conflicts)")
            yadm clone -f "$repo_url"
            ;;
        *)
            warn "Skipping yadm clone."
            return 1
            ;;
    esac

    if yadm status >/dev/null 2>&1; then
        info "yadm repo initialized."
    else
        warn "yadm repo still not initialized."
    fi
}

handle_bashd_location() {
    if [[ -d "$CANONICAL_BASHD_DIR" ]]; then
        info "Canonical bash.d found at $CANONICAL_BASHD_DIR."
        return 0
    fi

    if [[ -d "$LEGACY_BASHD_DIR" ]]; then
        local action
        action=$(ask_choice "Found legacy bash.d at $LEGACY_BASHD_DIR. Select action:" \
            "Move legacy to ${CANONICAL_BASHD_DIR}" \
            "Symlink ${CANONICAL_BASHD_DIR} -> ${LEGACY_BASHD_DIR}" \
            "Leave as-is" \
            "I don't know")
        case "$action" in
            "Move legacy to ${CANONICAL_BASHD_DIR}")
                if [[ -e "$CANONICAL_BASHD_DIR" ]]; then
                    warn "Target already exists: $CANONICAL_BASHD_DIR"
                else
                    mv "$LEGACY_BASHD_DIR" "$CANONICAL_BASHD_DIR"
                    info "Moved legacy bash.d to canonical location."
                fi
                ;;
            "Symlink ${CANONICAL_BASHD_DIR} -> ${LEGACY_BASHD_DIR}")
                ln -s "$LEGACY_BASHD_DIR" "$CANONICAL_BASHD_DIR"
                info "Symlink created."
                ;;
            *)
                warn "Leaving legacy bash.d in place."
                ;;
        esac
        return 0
    fi

    warn "No bash.d directory found at canonical or legacy location."
}

ensure_bashd_symlink() {
    if [[ ! -d "$CANONICAL_BASHD_DIR" && ! -d "$LEGACY_BASHD_DIR" ]]; then
        warn "No bash.d directory available to link."
        return 0
    fi

    local desired_target=""
    if [[ -d "$CANONICAL_BASHD_DIR" ]]; then
        desired_target="${CANONICAL_BASHD_DIR}/bashd"
    else
        desired_target="${LEGACY_BASHD_DIR}/bashd"
    fi

    if [[ -L "$BASHD_SYMLINK" ]]; then
        local current_target
        current_target="$(readlink "$BASHD_SYMLINK" 2>/dev/null || true)"
        if [[ "$current_target" == "$desired_target" ]]; then
            info "bashd symlink already set."
            return 0
        fi
        local update_choice
        update_choice=$(ask_yes_no_idk "Update ${BASHD_SYMLINK} to point to ${desired_target}?")
        if [[ "$update_choice" == "yes" ]]; then
            rm "$BASHD_SYMLINK"
            ln -s "$desired_target" "$BASHD_SYMLINK"
            info "bashd symlink updated."
        else
            warn "bashd symlink left unchanged."
        fi
    else
        local create_choice
        create_choice=$(ask_yes_no_idk "Create ${BASHD_SYMLINK} -> ${desired_target}?")
        if [[ "$create_choice" == "yes" ]]; then
            ln -s "$desired_target" "$BASHD_SYMLINK"
            info "bashd symlink created."
        else
            warn "Skipping bashd symlink creation."
        fi
    fi
}

maybe_add_bashd_to_yadm() {
    if ! command -v yadm >/dev/null 2>&1; then
        return 0
    fi
    if ! yadm status >/dev/null 2>&1; then
        return 0
    fi
    if [[ -d "$CANONICAL_BASHD_DIR" ]]; then
        local add_choice
        add_choice=$(ask_yes_no_idk "Add ${CANONICAL_BASHD_DIR} to yadm?")
        if [[ "$add_choice" == "yes" ]]; then
            yadm add "$CANONICAL_BASHD_DIR"
            info "Added bash.d to yadm."
        fi
    fi
}

main() {
    print_header
    scan_state
    render_report

    local mode
    mode=$(ask_choice "Select mode" \
        "Audit only (no changes)" \
        "Guided setup (recommended)" \
        "I don't know")

    case "$mode" in
        "Audit only (no changes)")
            info "Audit complete. No changes made."
            exit 0
            ;;
        "Guided setup (recommended)")
            ;;
        *)
            warn "No action selected."
            exit 0
            ;;
    esac

    ensure_yadm
    ensure_yadm_repo
    handle_bashd_location
    ensure_bashd_symlink
    maybe_add_bashd_to_yadm

    info "Unified install complete."
    info "If anything remains unclear, rerun this script in audit mode."
}

main "$@"
