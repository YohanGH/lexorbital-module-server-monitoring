#!/usr/bin/env bash
# ============================================================================
# LexOrbital Security Surveillance Module
# ============================================================================
# Monitors security: SSH attacks, brute-force, sudo anomalies
#
# Usage: ./surveillance-security.sh [--config /path/to/config]
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

readonly MODULE_NAME="security"
readonly MODULE_VERSION="1.0.0"

# Default thresholds
THRESHOLD_SSH_FAILED_WARNING="${THRESHOLD_SSH_FAILED_WARNING:-5}"
THRESHOLD_SSH_FAILED_CRITICAL="${THRESHOLD_SSH_FAILED_CRITICAL:-10}"
THRESHOLD_BRUTE_FORCE="${THRESHOLD_BRUTE_FORCE:-10}"
SUDO_ALLOWED_USERS="${SUDO_ALLOWED_USERS:-root,admin,deploy}"

# Time window for analysis (hours)
readonly ANALYSIS_WINDOW_HOURS=24

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
# SSH Security Monitoring
# ============================================================================

check_ssh_failed_logins() {
  local report="$1"
  
  log_debug "Checking SSH failed login attempts..."
  
  # Check if auth.log or secure log exists
  local auth_log=""
  if [[ -f /var/log/auth.log ]]; then
    auth_log="/var/log/auth.log"
  elif [[ -f /var/log/secure ]]; then
    auth_log="/var/log/secure"
  else
    log_warn "No auth log found"
    report=$(add_check "$report" "ssh.failed_logins" "SSH Failed Logins" "$STATUS_UNKNOWN" \
      "Unable to find auth log file")
    echo "$report"
    return
  fi
  
  # Get failed SSH attempts in the last 24 hours
  local since_date
  since_date=$(date -d "${ANALYSIS_WINDOW_HOURS} hours ago" "+%b %e" 2>/dev/null || date -v-${ANALYSIS_WINDOW_HOURS}H "+%b %e" 2>/dev/null || echo "")
  
  local failed_count
  if [[ -n "$since_date" ]]; then
    failed_count=$(grep -i "failed password\|authentication failure" "$auth_log" 2>/dev/null | grep "$since_date" | wc -l || echo "0")
  else
    # Fallback: use journalctl
    failed_count=$(journalctl -u sshd --since "${ANALYSIS_WINDOW_HOURS} hours ago" 2>/dev/null | grep -i "failed password\|authentication failure" | wc -l || echo "0")
  fi
  
  failed_count=${failed_count## }
  
  local status
  status=$(determine_status "$failed_count" "$THRESHOLD_SSH_FAILED_WARNING" "$THRESHOLD_SSH_FAILED_CRITICAL" "gt")
  
  local message
  case "$status" in
    "$STATUS_CRITICAL")
      message="Critical: ${failed_count} SSH failed login attempts in last ${ANALYSIS_WINDOW_HOURS}h"
      ;;
    "$STATUS_WARNING")
      message="Warning: ${failed_count} SSH failed login attempts in last ${ANALYSIS_WINDOW_HOURS}h"
      ;;
    *)
      message="${failed_count} SSH failed login attempts in last ${ANALYSIS_WINDOW_HOURS}h"
      ;;
  esac
  
  report=$(add_check "$report" "ssh.failed_logins" "SSH Failed Logins" "$status" "$message" \
    "$failed_count" "$THRESHOLD_SSH_FAILED_WARNING" "$THRESHOLD_SSH_FAILED_CRITICAL")
  
  echo "$report"
}

check_ssh_brute_force() {
  local report="$1"
  
  log_debug "Checking for SSH brute-force attacks..."
  
  # Find auth log
  local auth_log=""
  if [[ -f /var/log/auth.log ]]; then
    auth_log="/var/log/auth.log"
  elif [[ -f /var/log/secure ]]; then
    auth_log="/var/log/secure"
  else
    report=$(add_check "$report" "ssh.brute_force" "SSH Brute Force Detection" "$STATUS_UNKNOWN" \
      "Unable to find auth log file")
    echo "$report"
    return
  fi
  
  # Get recent failed attempts
  local temp_file
  temp_file=$(mktemp)
  
  # Extract IPs from failed SSH attempts (last 1000 lines to avoid performance issues)
  tail -n 1000 "$auth_log" 2>/dev/null | \
    grep -i "failed password" | \
    grep -oE "from [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | \
    awk '{print $2}' | \
    sort | uniq -c | sort -rn > "$temp_file" || true
  
  # Find IPs with more than threshold attempts
  local brute_force_ips
  brute_force_ips=$(awk -v threshold="$THRESHOLD_BRUTE_FORCE" '$1 >= threshold {print}' "$temp_file" | wc -l)
  brute_force_ips=${brute_force_ips## }
  
  local status
  if [[ "$brute_force_ips" -gt 0 ]]; then
    status="$STATUS_CRITICAL"
    
    # Pseudonymize IPs for logging
    local ip_list=""
    if is_gdpr_enabled; then
      ip_list=$(awk -v threshold="$THRESHOLD_BRUTE_FORCE" '$1 >= threshold {print $2}' "$temp_file" | head -n 5 | while read -r ip; do
        pseudonymize_ip "$ip"
      done | tr '\n' ', ' | sed 's/,$//')
    else
      ip_list=$(awk -v threshold="$THRESHOLD_BRUTE_FORCE" '$1 >= threshold {print $2}' "$temp_file" | head -n 5 | tr '\n' ', ' | sed 's/,$//')
    fi
    
    local message
    message="Brute-force attack detected from ${brute_force_ips} IP(s): ${ip_list}"
    
    report=$(add_check "$report" "ssh.brute_force" "SSH Brute Force Detection" "$status" "$message" "$brute_force_ips")
    report=$(add_alert "$report" "critical" "ssh.brute_force" "$message")
  else
    status="$STATUS_HEALTHY"
    report=$(add_check "$report" "ssh.brute_force" "SSH Brute Force Detection" "$status" \
      "No brute-force attacks detected" "0")
  fi
  
  rm -f "$temp_file"
  
  echo "$report"
}

check_ssh_successful_logins() {
  local report="$1"
  
  log_debug "Checking SSH successful logins..."
  
  # Count successful SSH logins in the last 24 hours
  local success_count
  success_count=$(journalctl -u sshd --since "${ANALYSIS_WINDOW_HOURS} hours ago" 2>/dev/null | \
    grep -i "accepted password\|accepted publickey" | wc -l || echo "0")
  success_count=${success_count## }
  
  local message
  message="${success_count} successful SSH login(s) in last ${ANALYSIS_WINDOW_HOURS}h"
  
  # This is informational only
  report=$(add_check "$report" "ssh.successful_logins" "SSH Successful Logins" "$STATUS_HEALTHY" \
    "$message" "$success_count")
  
  echo "$report"
}

# ============================================================================
# Sudo Monitoring
# ============================================================================

check_sudo_usage() {
  local report="$1"
  
  log_debug "Checking sudo usage..."
  
  # Count sudo commands in the last 24 hours
  local sudo_count
  sudo_count=$(journalctl --since "${ANALYSIS_WINDOW_HOURS} hours ago" 2>/dev/null | \
    grep -i "sudo:" | grep "COMMAND=" | wc -l || echo "0")
  sudo_count=${sudo_count## }
  
  local message
  message="${sudo_count} sudo command(s) executed in last ${ANALYSIS_WINDOW_HOURS}h"
  
  # This is informational only
  report=$(add_check "$report" "sudo.usage" "Sudo Command Usage" "$STATUS_HEALTHY" \
    "$message" "$sudo_count")
  
  echo "$report"
}

check_sudo_anomalies() {
  local report="$1"
  
  log_debug "Checking for sudo anomalies..."
  
  # Get sudo commands from unauthorized users
  local temp_file
  temp_file=$(mktemp)
  
  # Extract usernames from sudo logs
  journalctl --since "${ANALYSIS_WINDOW_HOURS} hours ago" 2>/dev/null | \
    grep -i "sudo:" | grep "COMMAND=" | \
    grep -oE "USER=[a-zA-Z0-9_-]+" | \
    cut -d'=' -f2 | sort | uniq > "$temp_file" || true
  
  # Convert allowed users to array
  IFS=',' read -ra ALLOWED_USERS <<< "$SUDO_ALLOWED_USERS"
  
  # Find unauthorized users
  local unauthorized_users=""
  while read -r user; do
    local is_allowed=false
    for allowed in "${ALLOWED_USERS[@]}"; do
      if [[ "$user" == "$allowed" ]]; then
        is_allowed=true
        break
      fi
    done
    
    if [[ "$is_allowed" == false ]]; then
      if is_gdpr_enabled; then
        unauthorized_users+="$(pseudonymize_username "$user"), "
      else
        unauthorized_users+="${user}, "
      fi
    fi
  done < "$temp_file"
  
  rm -f "$temp_file"
  
  # Remove trailing comma
  unauthorized_users=${unauthorized_users%, }
  
  local status
  local message
  if [[ -n "$unauthorized_users" ]]; then
    status="$STATUS_WARNING"
    message="Sudo usage detected from unauthorized user(s): ${unauthorized_users}"
    report=$(add_alert "$report" "warning" "sudo.anomalies" "$message")
  else
    status="$STATUS_HEALTHY"
    message="No sudo anomalies detected"
  fi
  
  report=$(add_check "$report" "sudo.anomalies" "Sudo Anomaly Detection" "$status" "$message")
  
  echo "$report"
}

# ============================================================================
# Failed Login Attempts (btmp)
# ============================================================================

check_btmp_entries() {
  local report="$1"
  
  log_debug "Checking btmp entries..."
  
  # Check if btmp exists
  if [[ ! -f /var/log/btmp ]]; then
    report=$(add_check "$report" "btmp.entries" "Failed Login Attempts (btmp)" "$STATUS_HEALTHY" \
      "No btmp log file found" "0")
    echo "$report"
    return
  fi
  
  # Count btmp entries (failed login attempts)
  local btmp_count
  btmp_count=$(lastb -F 2>/dev/null | grep -v "^$" | grep -v "^btmp" | wc -l || echo "0")
  btmp_count=${btmp_count## }
  
  local status
  if [[ "$btmp_count" -gt 20 ]]; then
    status="$STATUS_WARNING"
  else
    status="$STATUS_HEALTHY"
  fi
  
  local message
  message="${btmp_count} failed login attempt(s) recorded in btmp"
  
  report=$(add_check "$report" "btmp.entries" "Failed Login Attempts (btmp)" "$status" \
    "$message" "$btmp_count")
  
  echo "$report"
}

# ============================================================================
# Unusual Login Times (wtmp)
# ============================================================================

check_unusual_logins() {
  local report="$1"
  
  log_debug "Checking for unusual login times..."
  
  # Count logins in unusual hours (e.g., 2am-5am)
  local unusual_count
  unusual_count=$(last -F -n 100 2>/dev/null | \
    grep -E "0[2-5]:[0-9]{2}:[0-9]{2}" | wc -l || echo "0")
  unusual_count=${unusual_count## }
  
  local status
  local message
  if [[ "$unusual_count" -gt 5 ]]; then
    status="$STATUS_WARNING"
    message="${unusual_count} login(s) detected during unusual hours (2am-5am)"
  else
    status="$STATUS_HEALTHY"
    message="No unusual login times detected"
  fi
  
  report=$(add_check "$report" "wtmp.unusual_times" "Unusual Login Times" "$status" \
    "$message" "$unusual_count")
  
  echo "$report"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
  log_info "Starting security surveillance module v${MODULE_VERSION}"
  
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
LexOrbital Security Surveillance Module

Usage: $0 [options]

Options:
  --config PATH    Path to configuration file
  --help, -h       Show this help message

Checks:
  - SSH failed login attempts
  - SSH brute-force detection
  - Sudo usage and anomalies
  - Failed login attempts (btmp)
  - Unusual login times (wtmp)

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
  report=$(check_ssh_failed_logins "$report")
  report=$(check_ssh_brute_force "$report")
  report=$(check_ssh_successful_logins "$report")
  report=$(check_sudo_usage "$report")
  report=$(check_sudo_anomalies "$report")
  report=$(check_btmp_entries "$report")
  report=$(check_unusual_logins "$report")
  
  # Calculate worst status
  local worst_status
  worst_status=$(echo "$report" | jq -r '[.checks[].status] | unique | if any(. == "critical") then "critical" elif any(. == "warning") then "warning" elif any(. == "unknown") then "unknown" else "healthy" end')
  
  report=$(update_status "$report" "$worst_status")
  
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
  
  log_info "Security surveillance completed in ${exec_time}ms with status: ${worst_status}"
  
  # Exit with appropriate code
  case "$worst_status" in
    "$STATUS_CRITICAL") exit 2 ;;
    "$STATUS_WARNING") exit 1 ;;
    *) exit 0 ;;
  esac
}

# Run main function
main "$@"

