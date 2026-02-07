#!/usr/bin/env bash
# Hardware information dump script
# Gathers hardware modules and metadata as reported by the operating system

set -euo pipefail

# Pure function: returns header information
get_header() {
    local timestamp="$1"
    local hostname="$2"
    local kernel="$3"
    if [ -n "$timestamp" ]; then
        cat <<EOF
==========================================
Hardware Information Dump
Generated: $timestamp
Hostname: $hostname
Kernel: $kernel
==========================================

EOF
    else
        cat <<EOF
==========================================
Hardware Information Dump
Hostname: $hostname
Kernel: $kernel
==========================================

EOF
    fi
}

# Pure function: returns CPU information
get_cpu_info() {
    cat <<EOF
=== CPU INFORMATION ===

EOF
    if [ -f /proc/cpuinfo ]; then
        # Filter out dynamic cpu MHz values, keep static specification data
        grep -v "^cpu MHz" /proc/cpuinfo || cat /proc/cpuinfo
    fi
    echo ""
}

# Pure function: returns memory information
get_memory_info() {
    cat <<EOF
=== MEMORY INFORMATION ===

EOF
    if [ -f /proc/meminfo ]; then
        # Filter out dynamic runtime values, keep only static specification values (totals)
        grep -E "^(MemTotal|SwapTotal|Hugepagesize)" /proc/meminfo || cat /proc/meminfo
    fi
    echo ""
}

# Pure function: returns PCI device information
get_pci_info() {
    cat <<EOF
=== PCI DEVICES ===

EOF
    if command -v lspci &> /dev/null; then
        echo "--- Detailed PCI devices ---"
        lspci -vvv 2>/dev/null || lspci 2>/dev/null || echo "lspci not available"
        echo ""
        echo "--- PCI device tree ---"
        lspci -tv 2>/dev/null || echo "lspci tree view not available"
    else
        echo "lspci not available"
    fi
    echo ""
}

# Pure function: returns USB device information
get_usb_info() {
    cat <<EOF
=== USB DEVICES ===

EOF
    if command -v lsusb &> /dev/null; then
        echo "--- USB device tree ---"
        lsusb -tv 2>/dev/null || lsusb 2>/dev/null || echo "lsusb not available"
        echo ""
        echo "--- Detailed USB devices ---"
        set +o pipefail
        lsusb -v 2>/dev/null | head -500 || lsusb 2>/dev/null || echo "lsusb verbose not available"
        set -o pipefail
    else
        echo "lsusb not available"
    fi
    echo ""
}

# Pure function: returns block device information
get_block_info() {
    cat <<EOF
=== BLOCK DEVICES ===

EOF
    if command -v lsblk &> /dev/null; then
        lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE,UUID,MODEL,VENDOR,SERIAL,STATE 2>/dev/null || lsblk 2>/dev/null || echo "lsblk not available"
    else
        echo "lsblk not available"
    fi
    echo ""
}

# Pure function: returns kernel module information
get_kernel_modules_info() {
    cat <<EOF
=== KERNEL MODULES ===

EOF
    if [ -f /proc/modules ]; then
        echo "--- Loaded modules ---"
        cat /proc/modules
        echo ""
    fi
    
    if [ -d /sys/module ]; then
        echo "--- Module metadata from /sys/module ---"
        for module in /sys/module/*; do
            if [ -d "$module" ]; then
                modname=$(basename "$module")
                echo "Module: $modname"
                if [ -f "$module/version" ]; then
                    echo "  Version: $(cat "$module/version" 2>/dev/null || echo 'N/A')"
                fi
                if [ -f "$module/srcversion" ]; then
                    echo "  Source Version: $(cat "$module/srcversion" 2>/dev/null || echo 'N/A')"
                fi
                if [ -f "$module/refcnt" ]; then
                    echo "  Reference Count: $(cat "$module/refcnt" 2>/dev/null || echo 'N/A')"
                fi
                if [ -f "$module/taint" ]; then
                    taint=$(cat "$module/taint" 2>/dev/null)
                    if [ -n "$taint" ]; then
                        echo "  Taint: $taint"
                    fi
                fi
                if [ -d "$module/parameters" ]; then
                    echo "  Parameters:"
                    for param in "$module/parameters"/*; do
                        if [ -f "$param" ]; then
                            paramname=$(basename "$param")
                            paramval=$(cat "$param" 2>/dev/null || echo 'N/A')
                            echo "    $paramname = $paramval"
                        fi
                    done
                fi
                echo ""
            fi
        done
    fi
    echo ""
}

# Pure function: returns DMI/SMBIOS information
get_dmi_info() {
    cat <<EOF
=== DMI/SMBIOS INFORMATION ===

EOF
    if command -v dmidecode &> /dev/null; then
        if [ "$(id -u)" -eq 0 ]; then
            dmidecode 2>/dev/null || echo "dmidecode failed"
        else
            echo "Note: Running dmidecode requires root privileges"
            echo "Run with sudo for full DMI information"
            sudo dmidecode 2>/dev/null || echo "dmidecode not available or failed"
        fi
    else
        echo "dmidecode not available"
    fi
    echo ""
}

# Pure function: returns sysfs hardware class information
get_sysfs_info() {
    cat <<EOF
=== SYSFS HARDWARE INFORMATION ===

EOF
    if [ -d /sys/class ]; then
        echo "--- Hardware classes ---"
        for class in /sys/class/*; do
            if [ -d "$class" ]; then
                classname=$(basename "$class")
                echo "Class: $classname"
                count=$(find "$class" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
                echo "  Device count: $count"
                # List first few devices as examples
                for device in "$class"/*; do
                    if [ -d "$device" ] && [ "$(basename "$device")" != "power" ] && [ "$(basename "$device")" != "subsystem" ]; then
                        devname=$(basename "$device")
                        echo "    Device: $devname"
                        # Try to get some common attributes
                        for attr in name model vendor product uevent; do
                            if [ -f "$device/$attr" ]; then
                                val=$(cat "$device/$attr" 2>/dev/null | tr -d '\0' | head -3 2>/dev/null || echo 'N/A')
                                echo "      $attr: $val"
                            fi
                        done
                        # Only show first 3 devices per class to avoid too much output
                        count=$((count - 1))
                        if [ $count -lt 0 ]; then
                            break
                        fi
                    fi
                done
                echo ""
            fi
        done
    fi
    echo ""
}

# Pure function: returns network interface information
get_network_info() {
    cat <<EOF
=== NETWORK INTERFACES ===

EOF
    if command -v ip &> /dev/null; then
        ip -d link show 2>/dev/null || ip link show 2>/dev/null || echo "ip not available"
    elif command -v ifconfig &> /dev/null; then
        ifconfig -a 2>/dev/null || echo "ifconfig not available"
    else
        echo "Network tools not available"
    fi
    echo ""
    
    if [ -d /sys/class/net ]; then
        echo "--- Network interface details from /sys/class/net ---"
        for iface in /sys/class/net/*; do
            if [ -d "$iface" ]; then
                ifacename=$(basename "$iface")
                echo "Interface: $ifacename"
                if [ -f "$iface/address" ]; then
                    echo "  MAC Address: $(cat "$iface/address" 2>/dev/null || echo 'N/A')"
                fi
                if [ -f "$iface/type" ]; then
                    echo "  Type: $(cat "$iface/type" 2>/dev/null || echo 'N/A')"
                fi
                if [ -f "$iface/operstate" ]; then
                    echo "  State: $(cat "$iface/operstate" 2>/dev/null || echo 'N/A')"
                fi
                if [ -f "$iface/speed" ]; then
                    speed=$(cat "$iface/speed" 2>/dev/null || echo 'N/A')
                    echo "  Speed: $speed"
                fi
                if [ -d "$iface/device" ]; then
                    device=$(readlink -f "$iface/device" 2>/dev/null || echo 'N/A')
                    echo "  Device: $device"
                fi
                echo ""
            fi
        done
    fi
    echo ""
}

# Pure function: returns graphics device information
get_graphics_info() {
    cat <<EOF
=== GRAPHICS DEVICES ===

EOF
    if [ -d /sys/class/drm ]; then
        echo "--- DRM devices ---"
        for card in /sys/class/drm/card*; do
            if [ -d "$card" ]; then
                cardname=$(basename "$card")
                echo "Card: $cardname"
                if [ -f "$card/device/vendor" ]; then
                    vendor=$(cat "$card/device/vendor" 2>/dev/null || echo 'N/A')
                    echo "  Vendor: 0x$vendor"
                fi
                if [ -f "$card/device/device" ]; then
                    device=$(cat "$card/device/device" 2>/dev/null || echo 'N/A')
                    echo "  Device: 0x$device"
                fi
                if [ -f "$card/device/subsystem_vendor" ]; then
                    subvendor=$(cat "$card/device/subsystem_vendor" 2>/dev/null || echo 'N/A')
                    echo "  Subsystem Vendor: 0x$subvendor"
                fi
                if [ -f "$card/device/subsystem_device" ]; then
                    subdevice=$(cat "$card/device/subsystem_device" 2>/dev/null || echo 'N/A')
                    echo "  Subsystem Device: 0x$subdevice"
                fi
                # List connectors
                for conn in "$card"/*-*; do
                    if [ -d "$conn" ] && [ -f "$conn/status" ]; then
                        connname=$(basename "$conn")
                        status=$(cat "$conn/status" 2>/dev/null || echo 'unknown')
                        echo "  Connector $connname: $status"
                    fi
                done
                echo ""
            fi
        done
    fi
    
    if command -v glxinfo &> /dev/null; then
        echo "--- OpenGL information ---"
        set +o pipefail
        # Filter out dynamic "Currently available" memory, keep static specification values
        glxinfo -B 2>/dev/null | grep -v "Currently available dedicated video memory" | head -20 || echo "glxinfo not available or failed"
        set -o pipefail
    fi
    echo ""
}

# Pure function: returns audio device information
get_audio_info() {
    cat <<EOF
=== AUDIO DEVICES ===

EOF
    if [ -d /sys/class/sound ]; then
        echo "--- Sound cards ---"
        for card in /sys/class/sound/card*; do
            if [ -d "$card" ]; then
                cardname=$(basename "$card")
                echo "Card: $cardname"
                if [ -f "$card/id" ]; then
                    echo "  ID: $(cat "$card/id" 2>/dev/null || echo 'N/A')"
                fi
                if [ -f "$card/device/vendor" ]; then
                    vendor=$(cat "$card/device/vendor" 2>/dev/null || echo 'N/A')
                    echo "  Vendor: 0x$vendor"
                fi
                if [ -f "$card/device/device" ]; then
                    device=$(cat "$card/device/device" 2>/dev/null || echo 'N/A')
                    echo "  Device: 0x$device"
                fi
                echo ""
            fi
        done
    fi
    
    if command -v aplay &> /dev/null; then
        echo "--- ALSA playback devices ---"
        aplay -l 2>/dev/null || echo "aplay not available"
    fi
    echo ""
}

# Pure function: returns input device information
get_input_info() {
    cat <<EOF
=== INPUT DEVICES ===

EOF
    if [ -d /sys/class/input ]; then
        for input in /sys/class/input/input*; do
            if [ -d "$input" ]; then
                inputname=$(basename "$input")
                echo "Input: $inputname"
                if [ -f "$input/name" ]; then
                    echo "  Name: $(cat "$input/name" 2>/dev/null || echo 'N/A')"
                fi
                if [ -f "$input/phys" ]; then
                    echo "  Physical: $(cat "$input/phys" 2>/dev/null || echo 'N/A')"
                fi
                if [ -f "$input/uevent" ]; then
                    echo "  UEvent:"
                    cat "$input/uevent" 2>/dev/null | tr -d '\0' | sed 's/^/    /' || echo '    N/A'
                fi
                echo ""
            fi
        done
    fi
    echo ""
}

# Pure function: returns storage device information
get_storage_info() {
    cat <<EOF
=== STORAGE DEVICES ===

EOF
    if [ -d /sys/block ]; then
        for block in /sys/block/*; do
            if [ -d "$block" ]; then
                blockname=$(basename "$block")
                echo "Block device: $blockname"
                if [ -f "$block/size" ]; then
                    size=$(cat "$block/size" 2>/dev/null || echo '0')
                    size_gb=$((size * 512 / 1024 / 1024 / 1024))
                    echo "  Size: ${size_gb}GB (${size} sectors)"
                fi
                if [ -f "$block/device/vendor" ]; then
                    vendor=$(cat "$block/device/vendor" 2>/dev/null | tr -d ' ' || echo 'N/A')
                    echo "  Vendor: $vendor"
                fi
                if [ -f "$block/device/model" ]; then
                    model=$(cat "$block/device/model" 2>/dev/null | tr -d ' ' || echo 'N/A')
                    echo "  Model: $model"
                fi
                if [ -f "$block/device/serial" ]; then
                    serial=$(cat "$block/device/serial" 2>/dev/null | tr -d ' ' || echo 'N/A')
                    echo "  Serial: $serial"
                fi
                if [ -f "$block/queue/rotational" ]; then
                    rotational=$(cat "$block/queue/rotational" 2>/dev/null || echo 'N/A')
                    if [ "$rotational" = "0" ]; then
                        echo "  Type: SSD"
                    elif [ "$rotational" = "1" ]; then
                        echo "  Type: HDD"
                    else
                        echo "  Type: Unknown ($rotational)"
                    fi
                fi
                echo ""
            fi
        done
    fi
    echo ""
}

# Pure function: returns firmware information
get_firmware_info() {
    cat <<EOF
=== FIRMWARE INFORMATION ===

EOF
    if [ -d /sys/firmware ]; then
        echo "--- Firmware directories ---"
        set +o pipefail
        find /sys/firmware -type f -name "*" 2>/dev/null | head -50 | while IFS= read -r fwfile; do
            if [ -r "$fwfile" ]; then
                echo "File: $fwfile"
                # Handle files that may contain null bytes or binary data
                # Remove null bytes and limit output to first 5 lines
                content=$(cat "$fwfile" 2>/dev/null | tr -d '\0' | head -5 2>/dev/null || echo 'N/A')
                if [ "$content" != "N/A" ] && [ -n "$content" ]; then
                    echo "  Content: $content"
                else
                    echo "  Content: (binary or unreadable)"
                fi
            fi
        done
        set -o pipefail
    fi
    echo ""
}

# Pure function: returns ACPI information
get_acpi_info() {
    cat <<EOF
=== ACPI INFORMATION ===

EOF
    if [ -d /sys/firmware/acpi ]; then
        echo "--- ACPI tables ---"
        if [ -d /sys/firmware/acpi/tables ]; then
            ls -la /sys/firmware/acpi/tables/ 2>/dev/null || echo "Cannot list ACPI tables"
        fi
    fi
    echo ""
}

# Pure function: returns additional tool information
get_additional_tools_info() {
    cat <<EOF
=== ADDITIONAL TOOLS (if available) ===

EOF
    if command -v lshw &> /dev/null; then
        echo "--- lshw output ---"
        if [ "$(id -u)" -eq 0 ]; then
            set +o pipefail
            lshw -short 2>/dev/null | head -100 || echo "lshw failed"
            set -o pipefail
        else
            echo "Note: Full lshw output requires root privileges"
            set +o pipefail
            sudo lshw -short 2>/dev/null | head -100 || echo "lshw not available or failed"
            set -o pipefail
        fi
        echo ""
    fi
    
    if command -v inxi &> /dev/null; then
        echo "--- inxi output ---"
        inxi -Fxz 2>/dev/null || echo "inxi failed"
        echo ""
    fi
}

# Pure function: returns footer
get_footer() {
    cat <<EOF
==========================================
End of hardware dump
==========================================

Note: This output is impure and contains dynamic data that may change
between runs (e.g., CPU frequencies, memory usage, device states).
EOF
}

# Main entrypoint: aggregates all information and writes to stdout
main() {
    local timestamp=""
    local hostname
    local kernel
    local impure=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --impure)
                impure=true
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                echo "Usage: $0 [--impure]" >&2
                exit 1
                ;;
        esac
    done
    
    # Only generate timestamp if --impure flag is passed
    if [ "$impure" = true ]; then
        timestamp=$(date -Iseconds)
    fi
    
    hostname=$(hostname)
    kernel=$(uname -r)
    
    get_header "$timestamp" "$hostname" "$kernel"
    get_cpu_info
    get_memory_info
    get_pci_info
    get_usb_info
    get_block_info
    get_kernel_modules_info
    get_dmi_info
    get_sysfs_info
    get_network_info
    get_graphics_info
    get_audio_info
    get_input_info
    get_storage_info
    get_firmware_info
    get_acpi_info
    get_additional_tools_info
    get_footer
}

# Execute main function
main "$@"
