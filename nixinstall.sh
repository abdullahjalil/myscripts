#!/usr/bin/env bash
# nixinstall - Interactive NixOS installer (archinstall-style)
# Run from a minimal NixOS live environment as root

set -euo pipefail

# ─── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
DIM='\033[2m'

# ─── State ────────────────────────────────────────────────────────────────────
DISK=""
DISK_LAYOUT="gpt"   # gpt | mbr
FS_TYPE="ext4"      # ext4 | btrfs | xfs
SWAP_SIZE="0"
HOSTNAME="nixos"
TIMEZONE="Europe/London"
LOCALE="en_GB.UTF-8"
KEYMAP="uk"
USERNAME=""
USER_PASSWORD=""
ROOT_PASSWORD=""
DESKTOP=""          # none | gnome | kde | xfce | sway | hyprland
EXTRA_PKGS=()
ENABLE_SSH=false
ENABLE_FLAKES=true
BOOT_TYPE=""        # uefi | bios  (auto-detected)
EFI_PART=""
ROOT_PART=""
SWAP_PART=""

# ─── Helpers ──────────────────────────────────────────────────────────────────
header() {
    clear
    echo -e "${BOLD}${CYAN}"
    cat << 'EOF'
  ███╗   ██╗██╗██╗  ██╗██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗
  ████╗  ██║██║╚██╗██╔╝██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║
  ██╔██╗ ██║██║ ╚███╔╝ ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║
  ██║╚██╗██║██║ ██╔██╗ ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║
  ██║ ╚████║██║██╔╝ ██╗██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗
  ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝
EOF
    echo -e "${RESET}${DIM}  Interactive NixOS Installer  •  inspired by archinstall${RESET}"
    echo -e "${DIM}  ─────────────────────────────────────────────────────────${RESET}"
    echo ""
}

section() { echo -e "\n${BOLD}${BLUE}══ $1 ══${RESET}\n"; }
info()    { echo -e "  ${GREEN}✔${RESET}  $1"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET}  $1"; }
error()   { echo -e "  ${RED}✖${RESET}  $1" >&2; }
prompt()  { echo -e -n "  ${CYAN}?${RESET}  $1 "; }
step()    { echo -e "  ${BOLD}${BLUE}→${RESET}  $1"; }

confirm() {
    local msg="$1" default="${2:-n}"
    local yn_hint="[y/N]"
    [[ "$default" == "y" ]] && yn_hint="[Y/n]"
    prompt "$msg $yn_hint: "
    read -r ans
    ans="${ans:-$default}"
    [[ "$ans" =~ ^[Yy]$ ]]
}

pick_one() {
    # pick_one "Prompt" option1 option2 ...
    local prompt_msg="$1"; shift
    local options=("$@")
    echo -e "  ${CYAN}?${RESET}  ${prompt_msg}"
    local i=1
    for opt in "${options[@]}"; do
        echo -e "     ${DIM}${i})${RESET} ${opt}"
        ((i++))
    done
    local choice
    while true; do
        prompt "Enter number [1-${#options[@]}]: "
        read -r choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
            PICK_RESULT="${options[$((choice-1))]}"
            return 0
        fi
        warn "Invalid choice, try again."
    done
}

require_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root."
        exit 1
    fi
}

detect_boot() {
    if [[ -d /sys/firmware/efi/efivars ]]; then
        BOOT_TYPE="uefi"
        info "Detected UEFI firmware"
    else
        BOOT_TYPE="bios"
        info "Detected BIOS/Legacy firmware"
    fi
}

# ─── Step 1: Disk selection ────────────────────────────────────────────────────
select_disk() {
    section "Disk Selection"
    echo -e "  ${DIM}Available block devices:${RESET}\n"
    lsblk -dpno NAME,SIZE,MODEL | grep -v "loop" | while read -r line; do
        echo -e "  ${line}"
    done
    echo ""
    warn "ALL DATA on the selected disk will be ERASED."
    echo ""
    prompt "Enter disk path (e.g. /dev/sda, /dev/nvme0n1): "
    read -r DISK
    if [[ ! -b "$DISK" ]]; then
        error "Block device '$DISK' not found."
        select_disk
        return
    fi
    info "Selected disk: $DISK ($(lsblk -dno SIZE "$DISK"))"
    confirm "Continue with $DISK?" "n" || { select_disk; return; }
}

# ─── Step 2: Partition layout ──────────────────────────────────────────────────
configure_partitions() {
    section "Partition Layout"

    pick_one "Filesystem type:" "ext4" "btrfs" "xfs"
    FS_TYPE="$PICK_RESULT"
    info "Filesystem: $FS_TYPE"

    prompt "Swap size in GiB (0 to disable, or 'auto' for RAM-based): "
    read -r SWAP_SIZE
    SWAP_SIZE="${SWAP_SIZE:-0}"
    if [[ "$SWAP_SIZE" == "auto" ]]; then
        local ram_gib
        ram_gib=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024 / 1024 ))
        SWAP_SIZE="$ram_gib"
        info "Auto swap: ${SWAP_SIZE}GiB (matches RAM)"
    fi
    info "Swap: ${SWAP_SIZE}GiB"
}

# ─── Step 3: System settings ───────────────────────────────────────────────────
configure_system() {
    section "System Settings"

    prompt "Hostname [nixos]: "
    read -r HOSTNAME
    HOSTNAME="${HOSTNAME:-nixos}"
    info "Hostname: $HOSTNAME"

    # Timezone
    echo ""
    echo -e "  ${DIM}Common timezones (enter any valid tz or leave blank for Europe/London):${RESET}"
    echo -e "  ${DIM}Europe/London  |  Europe/Berlin  |  America/New_York  |  America/Los_Angeles  |  Asia/Tokyo${RESET}"
    echo ""
    prompt "Timezone [Europe/London]: "
    read -r TIMEZONE
    TIMEZONE="${TIMEZONE:-Europe/London}"
    if ! timedatectl list-timezones 2>/dev/null | grep -q "^${TIMEZONE}$"; then
        warn "Could not verify timezone (may be fine if tzdata is not loaded)"
    fi
    info "Timezone: $TIMEZONE"

    # Locale
    prompt "Locale [en_GB.UTF-8]: "
    read -r LOCALE
    LOCALE="${LOCALE:-en_GB.UTF-8}"
    info "Locale: $LOCALE"

    # Keymap
    prompt "Console keymap [uk]: "
    read -r KEYMAP
    KEYMAP="${KEYMAP:-uk}"
    info "Keymap: $KEYMAP"
}

# ─── Step 4: User accounts ─────────────────────────────────────────────────────
configure_users() {
    section "User Accounts"

    # Root password
    while true; do
        prompt "Root password: "
        read -rs ROOT_PASSWORD; echo
        prompt "Confirm root password: "
        read -rs root_confirm; echo
        [[ "$ROOT_PASSWORD" == "$root_confirm" ]] && break
        warn "Passwords don't match, try again."
    done
    info "Root password set"

    # Regular user
    prompt "Create a regular user? (recommended) [Y/n]: "
    read -r ans
    ans="${ans:-y}"
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        prompt "Username: "
        read -r USERNAME
        while [[ -z "$USERNAME" ]]; do
            warn "Username cannot be empty."
            prompt "Username: "
            read -r USERNAME
        done
        while true; do
            prompt "Password for $USERNAME: "
            read -rs USER_PASSWORD; echo
            prompt "Confirm password: "
            read -rs user_confirm; echo
            [[ "$USER_PASSWORD" == "$user_confirm" ]] && break
            warn "Passwords don't match, try again."
        done
        info "User '$USERNAME' configured"
    fi
}

# ─── Step 5: Desktop environment ──────────────────────────────────────────────
configure_desktop() {
    section "Desktop Environment"
    pick_one "Choose desktop environment:" \
        "none (headless/server)" \
        "GNOME" \
        "KDE Plasma" \
        "XFCE" \
        "Sway (Wayland tiling)" \
        "Hyprland (Wayland tiling)"
    case "$PICK_RESULT" in
        "none (headless/server)") DESKTOP="none" ;;
        "GNOME")                  DESKTOP="gnome" ;;
        "KDE Plasma")             DESKTOP="kde" ;;
        "XFCE")                   DESKTOP="xfce" ;;
        "Sway (Wayland tiling)")  DESKTOP="sway" ;;
        "Hyprland (Wayland tiling)") DESKTOP="hyprland" ;;
    esac
    info "Desktop: $DESKTOP"
}

# ─── Step 6: Extra options ─────────────────────────────────────────────────────
configure_extras() {
    section "Extra Options"

    if confirm "Enable SSH server?" "n"; then
        ENABLE_SSH=true
        info "SSH enabled"
    fi

    if confirm "Enable Nix Flakes + nix-command?" "y"; then
        ENABLE_FLAKES=true
        info "Flakes enabled"
    else
        ENABLE_FLAKES=false
    fi

    prompt "Extra packages to install (space-separated, e.g. 'git vim htop'): "
    read -r extra_raw
    if [[ -n "$extra_raw" ]]; then
        read -ra EXTRA_PKGS <<< "$extra_raw"
        info "Extra packages: ${EXTRA_PKGS[*]}"
    fi
}

# ─── Step 7: Summary ──────────────────────────────────────────────────────────
show_summary() {
    header
    section "Installation Summary"
    echo -e "  ${BOLD}Disk${RESET}           $DISK  ($(lsblk -dno SIZE "$DISK"))"
    echo -e "  ${BOLD}Boot type${RESET}      $BOOT_TYPE"
    echo -e "  ${BOLD}Filesystem${RESET}     $FS_TYPE"
    echo -e "  ${BOLD}Swap${RESET}           ${SWAP_SIZE}GiB"
    echo -e "  ${BOLD}Hostname${RESET}       $HOSTNAME"
    echo -e "  ${BOLD}Timezone${RESET}       $TIMEZONE"
    echo -e "  ${BOLD}Locale${RESET}         $LOCALE"
    echo -e "  ${BOLD}Keymap${RESET}         $KEYMAP"
    echo -e "  ${BOLD}Desktop${RESET}        $DESKTOP"
    if [[ -n "$USERNAME" ]]; then
        echo -e "  ${BOLD}User${RESET}           $USERNAME"
    fi
    echo -e "  ${BOLD}SSH${RESET}            $ENABLE_SSH"
    echo -e "  ${BOLD}Flakes${RESET}         $ENABLE_FLAKES"
    if [[ ${#EXTRA_PKGS[@]} -gt 0 ]]; then
        echo -e "  ${BOLD}Extra pkgs${RESET}     ${EXTRA_PKGS[*]}"
    fi
    echo ""
    warn "THIS WILL WIPE $DISK COMPLETELY."
    echo ""
    confirm "Proceed with installation?" "n"
}

# ─── Partitioning ─────────────────────────────────────────────────────────────
do_partition() {
    step "Partitioning $DISK..."

    # Wipe existing signatures
    wipefs -af "$DISK" >/dev/null 2>&1 || true
    sgdisk --zap-all "$DISK" >/dev/null 2>&1 || true

    if [[ "$BOOT_TYPE" == "uefi" ]]; then
        parted -s "$DISK" \
            mklabel gpt \
            mkpart ESP fat32 1MiB 513MiB \
            set 1 esp on \
            mkpart primary 513MiB 100%
        # Detect partition naming (nvme uses p1/p2, sda uses 1/2)
        if [[ "$DISK" =~ nvme|mmcblk ]]; then
            EFI_PART="${DISK}p1"
            ROOT_PART="${DISK}p2"
        else
            EFI_PART="${DISK}1"
            ROOT_PART="${DISK}2"
        fi
    else
        # BIOS: small bios_grub partition + rest for root (+ optional swap carved later)
        parted -s "$DISK" \
            mklabel gpt \
            mkpart primary 1MiB 3MiB \
            set 1 bios_grub on \
            mkpart primary 3MiB 100%
        if [[ "$DISK" =~ nvme|mmcblk ]]; then
            ROOT_PART="${DISK}p2"
        else
            ROOT_PART="${DISK}2"
        fi
    fi

    partprobe "$DISK"
    sleep 1
    info "Partitioned $DISK"
}

# ─── Format ───────────────────────────────────────────────────────────────────
do_format() {
    step "Formatting partitions..."

    if [[ "$BOOT_TYPE" == "uefi" ]]; then
        mkfs.fat -F32 -n NIXBOOT "$EFI_PART" >/dev/null
        info "EFI partition formatted (FAT32)"
    fi

    case "$FS_TYPE" in
        ext4)  mkfs.ext4 -L nixos -q "$ROOT_PART" >/dev/null ;;
        btrfs) mkfs.btrfs -L nixos -f "$ROOT_PART" >/dev/null ;;
        xfs)   mkfs.xfs -L nixos -f "$ROOT_PART" >/dev/null ;;
    esac
    info "Root partition formatted ($FS_TYPE)"
}

# ─── Mount ────────────────────────────────────────────────────────────────────
do_mount() {
    step "Mounting filesystems..."

    mount "$ROOT_PART" /mnt

    if [[ "$BOOT_TYPE" == "uefi" ]]; then
        mkdir -p /mnt/boot
        mount "$EFI_PART" /mnt/boot
    fi

    info "Filesystems mounted at /mnt"
}

# ─── Generate configuration.nix ───────────────────────────────────────────────
build_config() {
    step "Generating NixOS configuration..."

    nixos-generate-config --root /mnt >/dev/null 2>&1

    # ── Desktop module snippet ──────────────────────────────────────────
    local desktop_cfg=""
    case "$DESKTOP" in
        gnome)
            desktop_cfg='
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  environment.gnome.excludePackages = [ pkgs.gnome-tour ];'
            ;;
        kde)
            desktop_cfg='
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;'
            ;;
        xfce)
            desktop_cfg='
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.xfce.enable = true;'
            ;;
        sway)
            desktop_cfg='
  programs.sway.enable = true;
  programs.sway.wrapperFeatures.gtk = true;
  xdg.portal.enable = true;
  xdg.portal.wlr.enable = true;'
            ;;
        hyprland)
            desktop_cfg='
  programs.hyprland.enable = true;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];'
            ;;
        none) desktop_cfg="" ;;
    esac

    # ── SSH snippet ─────────────────────────────────────────────────────
    local ssh_cfg=""
    if [[ "$ENABLE_SSH" == "true" ]]; then
        ssh_cfg='
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "no";
  services.openssh.settings.PasswordAuthentication = true;'
    fi

    # ── Flakes snippet ──────────────────────────────────────────────────
    local flakes_cfg=""
    if [[ "$ENABLE_FLAKES" == "true" ]]; then
        flakes_cfg='
  nix.settings.experimental-features = [ "nix-command" "flakes" ];'
    fi

    # ── Extra packages ──────────────────────────────────────────────────
    local pkgs_line="git curl wget vim"
    if [[ ${#EXTRA_PKGS[@]} -gt 0 ]]; then
        pkgs_line="$pkgs_line ${EXTRA_PKGS[*]}"
    fi
    # Convert space-separated to nix list items
    local pkgs_nix=""
    for p in $pkgs_line; do
        pkgs_nix="$pkgs_nix pkgs.${p}"
    done

    # ── User block ──────────────────────────────────────────────────────
    local user_cfg=""
    if [[ -n "$USERNAME" ]]; then
        local hashed_pass
        hashed_pass=$(echo "$USER_PASSWORD" | mkpasswd -m sha-512 -s 2>/dev/null || \
                      openssl passwd -6 "$USER_PASSWORD" 2>/dev/null || \
                      echo "!")
        user_cfg="
  users.users.${USERNAME} = {
    isNormalUser = true;
    description = \"${USERNAME}\";
    hashedPassword = \"${hashed_pass}\";
    extraGroups = [ \"wheel\" \"networkmanager\" \"video\" \"audio\" ];
    shell = pkgs.bash;
  };"
    fi

    # ── Root password ───────────────────────────────────────────────────
    local root_hashed
    root_hashed=$(echo "$ROOT_PASSWORD" | mkpasswd -m sha-512 -s 2>/dev/null || \
                  openssl passwd -6 "$ROOT_PASSWORD" 2>/dev/null || \
                  echo "!")

    # ── Bootloader ──────────────────────────────────────────────────────
    local boot_cfg=""
    if [[ "$BOOT_TYPE" == "uefi" ]]; then
        boot_cfg='  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;'
    else
        boot_cfg="  boot.loader.grub.enable = true;
  boot.loader.grub.device = \"${DISK}\";"
    fi

    # ── Write configuration.nix ─────────────────────────────────────────
    cat > /mnt/etc/nixos/configuration.nix << NIXCFG
# Generated by nixinstall
# Edit this file to customise your NixOS system.
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # ── Boot ──────────────────────────────────────────────────────────────
${boot_cfg}

  # ── Networking ────────────────────────────────────────────────────────
  networking.hostName = "${HOSTNAME}";
  networking.networkmanager.enable = true;

  # ── Localisation ──────────────────────────────────────────────────────
  time.timeZone = "${TIMEZONE}";
  i18n.defaultLocale = "${LOCALE}";
  console.keyMap = "${KEYMAP}";

  # ── Desktop ───────────────────────────────────────────────────────────${desktop_cfg}

  # ── Sound (PipeWire) ──────────────────────────────────────────────────
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ── Packages ──────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [${pkgs_nix} ];

  # ── Users ─────────────────────────────────────────────────────────────
  users.users.root.hashedPassword = "${root_hashed}";
${user_cfg}

  # ── Security ──────────────────────────────────────────────────────────
  security.sudo.enable = true;

  # ── SSH ───────────────────────────────────────────────────────────────${ssh_cfg}

  # ── Nix settings ──────────────────────────────────────────────────────${flakes_cfg}
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  system.stateVersion = "24.11";
}
NIXCFG

    info "Configuration written to /mnt/etc/nixos/configuration.nix"
}

# ─── Install ──────────────────────────────────────────────────────────────────
do_install() {
    step "Running nixos-install..."
    echo ""
    nixos-install --no-root-passwd --root /mnt 2>&1 | while IFS= read -r line; do
        echo -e "  ${DIM}${line}${RESET}"
    done
    info "nixos-install complete"
}

# ─── Finish ───────────────────────────────────────────────────────────────────
finish() {
    header
    section "Installation Complete"
    echo -e "  ${GREEN}${BOLD}NixOS has been installed successfully!${RESET}"
    echo ""
    echo -e "  ${DIM}What to do next:${RESET}"
    echo -e "    1. Review  ${CYAN}/mnt/etc/nixos/configuration.nix${RESET}  before rebooting"
    echo -e "    2. Run ${CYAN}nixos-install${RESET} again if you made changes"
    echo -e "    3. Reboot: ${CYAN}reboot${RESET}"
    echo ""
    if confirm "Reboot now?" "n"; then
        umount -R /mnt
        reboot
    else
        info "Staying in live environment. Filesystems remain mounted at /mnt."
    fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    require_root
    header
    detect_boot

    select_disk
    configure_partitions
    configure_system
    configure_users
    configure_desktop
    configure_extras

    show_summary || { warn "Installation cancelled."; exit 0; }

    echo ""
    step "Starting installation..."
    echo ""

    do_partition
    do_format
    do_mount
    build_config
    do_install
    finish
}

main "$@"
