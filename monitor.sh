#!/bin/bash

# ========================================
# Linux Server Monitor
# ========================================

# ---------- Paths ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LOG_DIR="$SCRIPT_DIR/logs"
STATE_DIR="$SCRIPT_DIR/state"

MONITOR_LOG="$LOG_DIR/monitoring.log"
ALERT_LOG="$LOG_DIR/alerts.log"

mkdir -p "$LOG_DIR"
mkdir -p "$STATE_DIR"

touch "$MONITOR_LOG"
touch "$ALERT_LOG"


# ---------- Thresholds ----------
CPU_WARNING="${CPU_WARNING:-70}"
CPU_CRITICAL="${CPU_CRITICAL:-90}"

MEMORY_WARNING="${MEMORY_WARNING:-70}"
MEMORY_CRITICAL="${MEMORY_CRITICAL:-90}"

DISK_WARNING="${DISK_WARNING:-70}"
DISK_CRITICAL="${DISK_CRITICAL:-90}"

# ---------- Header ----------
show_header() {
    echo "========================================"
    echo "        LINUX SERVER MONITOR"
    echo "========================================"
    echo ""
}

# ---------- System Information ----------
show_system_info() {
    echo "Hostname       : $(hostname)"
    echo "Current User   : $(whoami)"
    echo "Uptime         : $(uptime -p)"
    echo "Date           : $(date)"
    echo ""
}

# ---------- CPU ----------
get_cpu_usage() {
    CPU_USAGE=$(top -bn1 | awk '/Cpu\(s\)/ {print 100 - $8}')
    CPU_USAGE=${CPU_USAGE%.*}
}

# ---------- Memory ----------
get_memory_usage() {
    MEMORY_USAGE=$(free | awk '/Mem:/ {
        printf "%.0f", ($3/$2) * 100
    }')
}

# ---------- Disk ----------
get_disk_usage() {
    DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
}

# ---------- Status ----------
get_status() {
    local usage=$1
    local warning=$2
    local critical=$3

    if [ "$usage" -ge "$critical" ]; then
        echo "CRITICAL"
    elif [ "$usage" -ge "$warning" ]; then
        echo "WARNING"
    else
        echo "OK"
    fi
}

# ---------- Alert ----------
send_alert() {
    local message="$1"
    local timestamp

    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] ALERT: $message" | tee -a "$ALERT_LOG"
}

# ---------- State Change ----------
handle_state_change() {
    local resource="$1"
    local current_state="$2"

    local state_file="$STATE_DIR/${resource}.state"
    local previous_state="UNKNOWN"

    if [ -f "$state_file" ]; then
        previous_state=$(cat "$state_file")
    fi

    if [ "$current_state" != "$previous_state" ]; then

        case "$current_state" in

            WARNING)
                send_alert "$resource changed from $previous_state to WARNING"
                ;;

            CRITICAL)
                send_alert "$resource changed from $previous_state to CRITICAL"
                ;;

            OK)
                if [ "$previous_state" = "WARNING" ] || \
                   [ "$previous_state" = "CRITICAL" ]; then
                    send_alert "$resource RECOVERED and returned to OK"
                fi
                ;;

        esac

        echo "$current_state" > "$state_file"
    fi
}

# ---------- Start Monitoring ----------
show_header
show_system_info

get_cpu_usage
get_memory_usage
get_disk_usage

CPU_STATUS=$(get_status "$CPU_USAGE" "$CPU_WARNING" "$CPU_CRITICAL")
MEMORY_STATUS=$(get_status "$MEMORY_USAGE" "$MEMORY_WARNING" "$MEMORY_CRITICAL")
DISK_STATUS=$(get_status "$DISK_USAGE" "$DISK_WARNING" "$DISK_CRITICAL")

# ---------- Handle State Changes ----------
handle_state_change "cpu" "$CPU_STATUS"
handle_state_change "memory" "$MEMORY_STATUS"
handle_state_change "disk" "$DISK_STATUS"

# ---------- Display ----------
echo "CPU Usage      : ${CPU_USAGE}% [$CPU_STATUS]"
echo "Memory Usage   : ${MEMORY_USAGE}% [$MEMORY_STATUS]"
echo "Disk Usage     : ${DISK_USAGE}% [$DISK_STATUS]"
echo ""

# ---------- Overall Status ----------
if [ "$CPU_STATUS" = "CRITICAL" ] || \
   [ "$MEMORY_STATUS" = "CRITICAL" ] || \
   [ "$DISK_STATUS" = "CRITICAL" ]; then

    OVERALL_STATUS="CRITICAL"

elif [ "$CPU_STATUS" = "WARNING" ] || \
     [ "$MEMORY_STATUS" = "WARNING" ] || \
     [ "$DISK_STATUS" = "WARNING" ]; then

    OVERALL_STATUS="WARNING"

else
    OVERALL_STATUS="OK"
fi

echo "Overall Status : $OVERALL_STATUS"

# ---------- Monitoring Log ----------
echo "[$(date '+%Y-%m-%d %H:%M:%S')] CPU=${CPU_USAGE}% Memory=${MEMORY_USAGE}% Disk=${DISK_USAGE}% Status=${OVERALL_STATUS}" \
    >> "$MONITOR_LOG"

# ---------- Exit Code ----------
if [ "$OVERALL_STATUS" = "CRITICAL" ]; then
    exit 2
elif [ "$OVERALL_STATUS" = "WARNING" ]; then
    exit 1
else
    exit 0
