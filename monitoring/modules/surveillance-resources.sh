#!/usr/bin/env bash
# ============================================================================
# LexOrbital Resources Surveillance Module
# ============================================================================
# Monitors system resources: CPU, RAM, disk, I/O
#
# Usage: ./surveillance-resources.sh [--config /path/to/config]
# Output: JSON report to stdout or configured directory
# ============================================================================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Load common library
# shellcheck source=../lib/surveillance-common.sh
source "${SCRIPT_DIR}/../lib/surveillance-common.sh"

# ============================================================================
# Module Configuration
# ============================================================================

readonly MODULE_NAME="resources"
readonly MODULE_VERSION="1.0.0"

# Default thresholds (can be overridden by config)
THRESHOLD_CPU_WARNING="${THRESHOLD_CPU_WARNING:-70}"
THRESHOLD_CPU_CRITICAL="${THRESHOLD_CPU_CRITICAL:-85}"
THRESHOLD_MEMORY_WARNING="${THRESHOLD_MEMORY_WARNING:-75}"
THRESHOLD_MEMORY_CRITICAL="${THRESHOLD_MEMORY_CRITICAL:-90}"
THRESHOLD_DISK_WARNING="${THRESHOLD_DISK_WARNING:-80}"
THRESHOLD_DISK_CRITICAL="${THRESHOLD_DISK_CRITICAL:-90}"
THRESHOLD_INODE_WARNING="${THRESHOLD_INODE_WARNING:-80}"
THRESHOLD_INODE_CRITICAL="${THRESHOLD_INODE_CRITICAL:-90}"
THRESHOLD_LOAD_WARNING="${THRESHOLD_LOAD_WARNING:-2.0}"
THRESHOLD_LOAD_CRITICAL="${THRESHOLD_LOAD_CRITICAL:-4.0}"

# ============================================================================
# Load Configuration
# ============================================================================

load_config() {
  local config_file="${1:-${SURVEILLANCE_CONFIG_DIR}/surveillance.conf}"
  
  if [[ -f "$config_file" ]]; then
    log_info "Loading configuration from ${config_file}"
    # shellcheck source=/dev/null
    source "$config_file"
  else
    log_warn "Configuration file not found: ${config_file}, using defaults"
  fi
}

# ============================================================================
# CPU Monitoring
# ============================================================================

check_cpu_usage() {
  local report="$1"
  
  log_debug "Checking CPU usage..."
  
  # Get CPU usage using top (works on most systems)
  local cpu_usage
  cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
  
  # Fallback: use mpstat if available
  if [[ -z "$cpu_usage" ]] && command -v mpstat &>/dev/null; then
    cpu_usage=$(mpstat 1 1 | awk '/Average/ {print 100 - $NF}')
  fi
  
  # Fallback: use /proc/stat (basic)
  if [[ -z "$cpu_usage" ]] || [[ "$cpu_usage" == "100" ]]; then
    cpu_usage=$(awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else print ($2+$4-u1) * 100 / (t-t1) }' \
      <(grep 'cpu ' /proc/stat) <(sleep 1; grep 'cpu ' /proc/stat) 2>/dev/null || echo "0")
  fi
  
  cpu_usage=$(printf "%.1f" "$cpu_usage" 2>/dev/null || echo "0")
  
  local status
  status=$(determine_status "$cpu_usage" "$THRESHOLD_CPU_WARNING" "$THRESHOLD_CPU_CRITICAL" "gt")
  
  local message
  case "$status" in
    "$STATUS_CRITICAL")
      message="CPU usage is critical: ${cpu_usage}%"
      ;;
    "$STATUS_WARNING")
      message="CPU usage is high: ${cpu_usage}%"
      ;;
    *)
      message="CPU usage is normal: ${cpu_usage}%"
      ;;
  esac
  
  report=$(add_check "$report" "cpu.usage" "CPU Usage" "$status" "$message" \
    "$cpu_usage" "$THRESHOLD_CPU_WARNING" "$THRESHOLD_CPU_CRITICAL")
  
  echo "$report"
}

check_cpu_load() {
  local report="$1"
  
  log_debug "Checking CPU load average..."
  
  # Get load averages
  local load_1min load_5min load_15min
  read -r load_1min load_5min load_15min _ _ < /proc/loadavg
  
  # Get number of CPU cores
  local cpu_cores
  cpu_cores=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)
  
  # Calculate load per core
  local load_per_core
  load_per_core=$(awk "BEGIN {printf \"%.2f\", $load_1min / $cpu_cores}")
  
  local status
  status=$(determine_status "${load_per_core%.*}" "${THRESHOLD_LOAD_WARNING%.*}" "${THRESHOLD_LOAD_CRITICAL%.*}" "gt")
  
  local message
  message="Load average: ${load_1min}, ${load_5min}, ${load_15min} (${cpu_cores} cores, ${load_per_core} per core)"
  
  report=$(add_check "$report" "cpu.load" "CPU Load Average" "$status" "$message" \
    "$load_per_core" "$THRESHOLD_LOAD_WARNING" "$THRESHOLD_LOAD_CRITICAL")
  
  echo "$report"
}

# ============================================================================
# Memory Monitoring
# ============================================================================

check_memory_usage() {
  local report="$1"
  
  log_debug "Checking memory usage..."
  
  # Get memory info from /proc/meminfo
  local mem_total mem_available mem_free mem_buffers mem_cached
  
  while IFS=: read -r key value; do
    case "$key" in
      "MemTotal") mem_total=${value% kB} ;;
      "MemAvailable") mem_available=${value% kB} ;;
      "MemFree") mem_free=${value% kB} ;;
      "Buffers") mem_buffers=${value% kB} ;;
      "Cached") mem_cached=${value% kB} ;;
    esac
  done < /proc/meminfo
  
  # Remove leading spaces
  mem_total=${mem_total## }
  mem_available=${mem_available## }
  mem_free=${mem_free## }
  mem_buffers=${mem_buffers## }
  mem_cached=${mem_cached## }
  
  # Calculate memory usage percentage
  local mem_used_percent
  if [[ -n "$mem_available" ]]; then
    mem_used_percent=$(awk "BEGIN {printf \"%.1f\", (1 - $mem_available / $mem_total) * 100}")
  else
    # Fallback for older kernels without MemAvailable
    local mem_used=$((mem_total - mem_free - mem_buffers - mem_cached))
    mem_used_percent=$(awk "BEGIN {printf \"%.1f\", $mem_used / $mem_total * 100}")
  fi
  
  local status
  status=$(determine_status "$mem_used_percent" "$THRESHOLD_MEMORY_WARNING" "$THRESHOLD_MEMORY_CRITICAL" "gt")
  
  local message
  local mem_total_gb mem_available_gb
  mem_total_gb=$(awk "BEGIN {printf \"%.1f\", $mem_total / 1024 / 1024}")
  mem_available_gb=$(awk "BEGIN {printf \"%.1f\", ${mem_available:-0} / 1024 / 1024}")
  
  message="Memory usage: ${mem_used_percent}% (${mem_available_gb}GB / ${mem_total_gb}GB available)"
  
  report=$(add_check "$report" "memory.used" "Memory Usage" "$status" "$message" \
    "$mem_used_percent" "$THRESHOLD_MEMORY_WARNING" "$THRESHOLD_MEMORY_CRITICAL")
  
  echo "$report"
}

check_swap_usage() {
  local report="$1"
  
  log_debug "Checking swap usage..."
  
  # Get swap info
  local swap_total swap_free
  
  while IFS=: read -r key value; do
    case "$key" in
      "SwapTotal") swap_total=${value% kB} ;;
      "SwapFree") swap_free=${value% kB} ;;
    esac
  done < /proc/meminfo
  
  swap_total=${swap_total## }
  swap_free=${swap_free## }
  
  # Check if swap is configured
  if [[ "$swap_total" == "0" ]]; then
    report=$(add_check "$report" "memory.swap" "Swap Usage" "$STATUS_HEALTHY" \
      "No swap configured" "0" "$THRESHOLD_MEMORY_WARNING" "$THRESHOLD_MEMORY_CRITICAL")
    echo "$report"
    return
  fi
  
  # Calculate swap usage
  local swap_used=$((swap_total - swap_free))
  local swap_used_percent
  swap_used_percent=$(awk "BEGIN {printf \"%.1f\", $swap_used / $swap_total * 100}")
  
  local status
  status=$(determine_status "$swap_used_percent" "$THRESHOLD_MEMORY_WARNING" "$THRESHOLD_MEMORY_CRITICAL" "gt")
  
  local message
  local swap_total_gb swap_used_gb
  swap_total_gb=$(awk "BEGIN {printf \"%.1f\", $swap_total / 1024 / 1024}")
  swap_used_gb=$(awk "BEGIN {printf \"%.1f\", $swap_used / 1024 / 1024}")
  
  message="Swap usage: ${swap_used_percent}% (${swap_used_gb}GB / ${swap_total_gb}GB used)"
  
  report=$(add_check "$report" "memory.swap" "Swap Usage" "$status" "$message" \
    "$swap_used_percent" "$THRESHOLD_MEMORY_WARNING" "$THRESHOLD_MEMORY_CRITICAL")
  
  echo "$report"
}

# ============================================================================
# Disk Monitoring
# ============================================================================

check_disk_usage() {
  local report="$1"
  local mount_point="$2"
  local check_id="$3"
  
  log_debug "Checking disk usage for ${mount_point}..."
  
  # Get disk usage
  local disk_info
  disk_info=$(df -h "$mount_point" 2>/dev/null | tail -n 1)
  
  if [[ -z "$disk_info" ]]; then
    log_warn "Unable to get disk info for ${mount_point}"
    report=$(add_check "$report" "$check_id" "Disk Usage ${mount_point}" "$STATUS_UNKNOWN" \
      "Unable to get disk information")
    echo "$report"
    return
  fi
  
  local size used avail percent
  read -r _ size used avail percent _ <<<"$disk_info"
  
  # Remove % sign
  percent=${percent%\%}
  
  local status
  status=$(determine_status "$percent" "$THRESHOLD_DISK_WARNING" "$THRESHOLD_DISK_CRITICAL" "gt")
  
  local message
  message="Disk usage ${mount_point}: ${percent}% (${avail} available of ${size})"
  
  report=$(add_check "$report" "$check_id" "Disk Usage ${mount_point}" "$status" "$message" \
    "$percent" "$THRESHOLD_DISK_WARNING" "$THRESHOLD_DISK_CRITICAL")
  
  echo "$report"
}

check_all_disks() {
  local report="$1"
  
  # Check critical mount points
  report=$(check_disk_usage "$report" "/" "disk.root.usage")
  
  if mountpoint -q /var 2>/dev/null; then
    report=$(check_disk_usage "$report" "/var" "disk.var.usage")
  fi
  
  if mountpoint -q /home 2>/dev/null; then
    report=$(check_disk_usage "$report" "/home" "disk.home.usage")
  fi
  
  echo "$report"
}

check_inode_usage() {
  local report="$1"
  
  log_debug "Checking inode usage..."
  
  # Get inode usage for root
  local inode_info
  inode_info=$(df -i / 2>/dev/null | tail -n 1)
  
  if [[ -z "$inode_info" ]]; then
    log_warn "Unable to get inode info"
    echo "$report"
    return
  fi
  
  local inodes_total inodes_used inodes_free percent
  read -r _ inodes_total inodes_used inodes_free percent _ <<<"$inode_info"
  
  # Remove % sign
  percent=${percent%\%}
  
  local status
  status=$(determine_status "$percent" "$THRESHOLD_INODE_WARNING" "$THRESHOLD_INODE_CRITICAL" "gt")
  
  local message
  message="Inode usage: ${percent}% (${inodes_free} available of ${inodes_total})"
  
  report=$(add_check "$report" "disk.inodes" "Inode Usage" "$status" "$message" \
    "$percent" "$THRESHOLD_INODE_WARNING" "$THRESHOLD_INODE_CRITICAL")
  
  echo "$report"
}

# ============================================================================
# I/O Monitoring
# ============================================================================

check_io_stats() {
  local report="$1"
  
  log_debug "Checking I/O statistics..."
  
  # Check if iostat is available
  if ! command -v iostat &>/dev/null; then
    log_debug "iostat not available, skipping I/O checks"
    echo "$report"
    return
  fi
  
  # Get I/O stats (1 second sample)
  local io_stats
  io_stats=$(iostat -dx 1 2 2>/dev/null | tail -n +4 | tail -n 1)
  
  if [[ -z "$io_stats" ]]; then
    echo "$report"
    return
  fi
  
  local read_kb write_kb
  read_kb=$(echo "$io_stats" | awk '{print $6}')
  write_kb=$(echo "$io_stats" | awk '{print $7}')
  
  local message
  message="I/O rates: ${read_kb} KB/s read, ${write_kb} KB/s write"
  
  report=$(add_check "$report" "io.stats" "I/O Statistics" "$STATUS_HEALTHY" "$message")
  
  echo "$report"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
  log_info "Starting resources surveillance module v${MODULE_VERSION}"
  
  local start_time
  start_time=$(get_time_ms)
  
  # Parse arguments
  local config_file=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --config)
        config_file="$2"
        shift 2
        ;;
      --help|-h)
        cat <<EOF
LexOrbital Resources Surveillance Module

Usage: $0 [options]

Options:
  --config PATH    Path to configuration file
  --help, -h       Show this help message

Environment Variables:
  SURVEILLANCE_DEBUG    Enable debug logging (true/false)
  SURVEILLANCE_DIR      Base surveillance directory

Output:
  JSON report to stdout
EOF
        exit 0
        ;;
      *)
        print_error "Unknown option: $1"
        exit 1
        ;;
    esac
  done
  
  # Load configuration
  if [[ -n "$config_file" ]]; then
    load_config "$config_file"
  else
    load_config
  fi
  
  # Initialize report
  local report
  report=$(init_report "$MODULE_NAME")
  
  # Perform checks
  report=$(check_cpu_usage "$report")
  report=$(check_cpu_load "$report")
  report=$(check_memory_usage "$report")
  report=$(check_swap_usage "$report")
  report=$(check_all_disks "$report")
  report=$(check_inode_usage "$report")
  report=$(check_io_stats "$report")
  
  # Calculate worst status
  local worst_status
  worst_status=$(echo "$report" | jq -r '[.checks[].status] | unique | if any(. == "critical") then "critical" elif any(. == "warning") then "warning" elif any(. == "unknown") then "unknown" else "healthy" end')
  
  report=$(update_status "$report" "$worst_status")
  
  # Add alerts if necessary
  if [[ "$worst_status" == "$STATUS_CRITICAL" ]]; then
    local critical_checks
    critical_checks=$(echo "$report" | jq -r '.checks[] | select(.status == "critical") | .name' | tr '\n' ', ' | sed 's/,$//')
    report=$(add_alert "$report" "critical" "$MODULE_NAME" "Critical resource issues detected: ${critical_checks}")
  fi
  
  # Update execution time
  local end_time exec_time
  end_time=$(get_time_ms)
  exec_time=$((end_time - start_time))
  report=$(update_execution_time "$report" "$exec_time")
  
  # Save report
  local output_file="${SURVEILLANCE_REPORTS_DIR}/${MODULE_NAME}.json"
  save_report "$report" "$output_file"
  
  # Output to stdout
  echo "$report" | jq '.'
  
  log_info "Resources surveillance completed in ${exec_time}ms with status: ${worst_status}"
  
  # Exit with appropriate code
  case "$worst_status" in
    "$STATUS_CRITICAL") exit 2 ;;
    "$STATUS_WARNING") exit 1 ;;
    *) exit 0 ;;
  esac
}

# Run main function
main "$@"

