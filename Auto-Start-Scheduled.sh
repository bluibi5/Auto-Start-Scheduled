#!/bin/bash
# # Runs any program at a specific date, time and time zone.
#
# Usage:
#   sudo ./Auto-Start-Scheduled.sh PROGRAM DATE TIME TIMEZONE [INTERFACE] [-- extra args...]
#
# Examples:
#   sudo ./Auto-Start-Scheduled.sh wireshark 2026-11-24 09:00 America/New_York wlan0mon
#   sudo ./Auto-Start-Scheduled.sh tcpdump   2026-11-24 16:00 America/Los_Angeles wlan0mon
#   sudo ./Auto-Start-Scheduled.sh airodump-ng 2026-11-24 16:00 UTC wlan0mon
#   sudo ./Auto-Start-Scheduled.sh tshark 2026-11-24 16:00 UTC wlan0mon -- -i {IFACE} -w /root/cap.pcapng
#   sudo ./Auto-Start-Scheduled.sh /root/myscript.sh 2026-11-24 16:00 UTC
#
#   PROGRAM   command name or full path
#   DATE      YYYY-MM-DD
#   TIME      24-hour HH:MM (16:00 = 4:00 PM)
#   TIMEZONE  IANA name, not an abbreviation like PST/EST
#             (e.g. America/Los_Angeles, America/New_York, UTC)
#             Full list: timedatectl list-timezones
#   INTERFACE optional. If given, it's passed to the program automatically
#             (-i IFACE for most tools, positional for the aircrack-ng suite,
#             -c IFACE for kismet).
#   -- args   optional. Everything after "--" is passed to the program exactly
#             as written, and {IFACE} is replaced with INTERFACE. When used,
#             no automatic interface arguments are added.

set -euo pipefail

usage() {
    echo "Usage: sudo $0 PROGRAM DATE TIME TIMEZONE [INTERFACE] [-- extra args...]"
    echo "Example: sudo $0 wireshark 2026-11-24 16:00 America/Los_Angeles wlan0mon"
    exit 1
}

if [[ $# -lt 4 ]]; then
    usage
fi

PROGRAM="$1"
TARGET_DATE="$2"    # YYYY-MM-DD
TARGET_TIME="$3"    # HH:MM (24-hour)
TARGET_TZ="$4"      # IANA time zone name
shift 4

# Optional interface (anything that isn't "--")
IFACE=""
if [[ $# -gt 0 && "$1" != "--" ]]; then
    IFACE="$1"
    shift
fi

# Optional extra arguments after "--"
EXTRA_ARGS=()
if [[ $# -gt 0 ]]; then
    if [[ "$1" != "--" ]]; then
        usage
    fi
    shift
    EXTRA_ARGS=("$@")
fi

if [[ $EUID -ne 0 ]]; then
    echo "Run as root: sudo $0 $*"
    exit 1
fi

# Resolve the program now so we fail early, not after waiting
PROGRAM_PATH=$(command -v "$PROGRAM" 2>/dev/null) || {
    echo "Program '$PROGRAM' not found. Check the name/path or install it."
    exit 1
}

# Validate the interface if one was given
if [[ -n "$IFACE" ]] && ! ip link show "$IFACE" >/dev/null 2>&1; then
    echo "Interface $IFACE not found. For monitor mode try: sudo airmon-ng start wlan0"
    exit 1
fi

if [[ ! -e "/usr/share/zoneinfo/$TARGET_TZ" ]]; then
    echo "Unknown time zone '$TARGET_TZ'. Use an IANA name (see: timedatectl list-timezones)."
    echo "Abbreviations like PST/EST are not accepted; use America/Los_Angeles, America/New_York, etc."
    exit 1
fi

# Build the argument list
CMD_ARGS=()
if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
    # User-supplied args; substitute {IFACE}
    for a in "${EXTRA_ARGS[@]}"; do
        CMD_ARGS+=("${a//\{IFACE\}/$IFACE}")
    done
elif [[ -n "$IFACE" ]]; then
    # Automatic interface handling based on program name
    case "$(basename "$PROGRAM_PATH")" in
        wireshark)
            CMD_ARGS=(-i "$IFACE" -k) ;;               # -k = start capturing immediately
        airodump-ng|aireplay-ng|besside-ng|airbase-ng)
            CMD_ARGS=("$IFACE") ;;                     # interface is positional
        kismet)
            CMD_ARGS=(-c "$IFACE") ;;
        *)
            CMD_ARGS=(-i "$IFACE") ;;                  # tshark, tcpdump, dumpcap, etc.
    esac
fi

# Convert the target date/time in the chosen time zone to epoch seconds
TARGET=$(TZ="$TARGET_TZ" date -d "$TARGET_DATE $TARGET_TIME" +%s 2>/dev/null) || {
    echo "Invalid date/time: '$TARGET_DATE $TARGET_TIME'. Use YYYY-MM-DD and HH:MM."
    exit 1
}

NOW=$(date +%s)
WAIT=$(( TARGET - NOW ))

if (( WAIT <= 0 )); then
    echo "Target time $TARGET_DATE $TARGET_TIME ($TARGET_TZ) has already passed."
    exit 1
fi

echo "Now            : $(date '+%F %T %Z')"
echo "Start (target) : $(TZ="$TARGET_TZ" date -d "@$TARGET" '+%F %T %Z')"
echo "Start (local)  : $(date -d "@$TARGET" '+%F %T %Z')"
echo "Command        : $PROGRAM_PATH ${CMD_ARGS[*]:-}"
echo "Waiting ${WAIT}s..."

sleep "$WAIT"

echo "Starting at $(date '+%F %T %Z')"
export DISPLAY="${DISPLAY:-:0}"   # needed for GUI programs like wireshark
exec "$PROGRAM_PATH" "${CMD_ARGS[@]}"
