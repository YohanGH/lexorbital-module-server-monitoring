#!/usr/bin/env bash
# ============================================================================
# LexOrbital File Integrity Surveillance Module
# ============================================================================
# Monitors file integrity: checksums, permissions, modifications
#
# Usage: ./surveillance-integrity.sh [--config /path/to/config] [--init]
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

readonly MODULE_NAME="integrity"
readonly MODULE_VERSION="1.0.0"

# Default configuration
INTEGRITY_MONITORED_PATHS="${INTEGRITY_MONITORED_PATHS:-/etc/passwd,/etc/shadow,/etc/group,/etc/ssh/sshd_config}"
INTEGRITY_CHECKSUM_FILE="${INTEGRITY_CHECKSUM_FILE:-${SURVEILLANCE_DIR}/checksums/file-integrity.db}"

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
# Checksum Database Management
# ============================================================================

initialize_checksums() {
  log_info "Initializing checksum database..."
  
  # Create checksum directory
  mkdir -p "$(dirname "${INTEGRITY_CHECKSUM_FILE}")"
  
  # Clear existing database
  > "${INTEGRITY_CHECKSUM_FILE}"
  
  # Convert paths to array
  IFS=',' read -ra MONITORED_FILES <<< "$INTEGRITY_MONITORED_PATHS"
  
  local count=0
  for file_path in "${MONITORED_FILES[@]}"; do
    if [[ -f "$file_path" ]]; then
      local checksum permissions owner group mtime
      checksum=$(sha256sum "$file_path" 2>/dev/null | awk '{print $1}')
      permissions=$(stat -c "%a" "$file_path" 2>/dev/null || stat -f "%OLp" "$file_path" 2>/dev/null)
      owner=$(stat -c "%U" "$file_path" 2>/dev/null || stat -f "%Su" "$file_path" 2>/dev/null)
      group=$(stat -c "%G" "$file_path" 2>/dev/null || stat -f "%Sg" "$file_path" 2>/dev/null)
      mtime=$(stat -c "%Y" "$file_path" 2>/dev/null || stat -f "%m" "$file_path" 2>/dev/null)
      
      echo "${file_path}|${checksum}|${permissions}|${owner}|${group}|${mtime}" >> "${INTEGRITY_CHECKSUM_FILE}"
      count=$((count + 1))
    else
      log_warn "File not found: ${file_path}"
    fi
  done
  
  chmod 640 "${INTEGRITY_CHECKSUM_FILE}"
  
  log_info "Initialized checksums for ${count} file(s)"
  print_success "Checksum database initialized with ${count} files"
}

# ============================================================================
# File Integrity Checks
# ============================================================================

check_file_checksums() {
  local report="$1"
  
  log_debug "Checking file checksums..."
  
  # Check if checksum database exists
  if [[ ! -f "${INTEGRITY_CHECKSUM_FILE}" ]]; then
    report=$(add_check "$report" "integrity.checksums" "File Checksums" "$STATUS_WARNING" \
      "Checksum database not initialized. Run with --init flag.")
    echo "$report"
    return
  fi
  
  local modified_files=""
  local modified_count=0
  
  while IFS='|' read -r file_path stored_checksum stored_perms stored_owner stored_group stored_mtime; do
    if [[ ! -f "$file_path" ]]; then
      modified_files+="${file_path} (deleted), "
      modified_count=$((modified_count + 1))
      log_warn "File deleted: ${file_path}"
      continue
    fi
    
    local current_checksum
    current_checksum=$(sha256sum "$file_path" 2>/dev/null | awk '{print $1}')
    
    if [[ "$current_checksum" != "$stored_checksum" ]]; then
      modified_files+="${file_path}, "
      modified_count=$((modified_count + 1))
      log_warn "File modified: ${file_path}"
    fi
  done < "${INTEGRITY_CHECKSUM_FILE}"
  
  # Remove trailing comma
  modified_files=${modified_files%, }
  
  local status
  local message
  if [[ "$modified_count" -gt 0 ]]; then
    status="$STATUS_CRITICAL"
    message="File integrity violation: ${modified_files}"
    report=$(add_alert "$report" "critical" "integrity.checksums" "$message")
  else
    status="$STATUS_HEALTHY"
    message="All monitored files are intact"
  fi
  
  report=$(add_check "$report" "integrity.checksums" "File Checksums" "$status" "$message" "$modified_count")
  
  echo "$report"
}

check_file_permissions() {
  local report="$1"
  
  log_debug "Checking file permissions..."
  
  if [[ ! -f "${INTEGRITY_CHECKSUM_FILE}" ]]; then
    echo "$report"
    return
  fi
  
  local permission_issues=""
  local issue_count=0
  
  while IFS='|' read -r file_path stored_checksum stored_perms stored_owner stored_group stored_mtime; do
    if [[ ! -f "$file_path" ]]; then
      continue
    fi
    
    local current_perms current_owner current_group
    current_perms=$(stat -c "%a" "$file_path" 2>/dev/null || stat -f "%OLp" "$file_path" 2>/dev/null)
    current_owner=$(stat -c "%U" "$file_path" 2>/dev/null || stat -f "%Su" "$file_path" 2>/dev/null)
    current_group=$(stat -c "%G" "$file_path" 2>/dev/null || stat -f "%Sg" "$file_path" 2>/dev/null)
    
    if [[ "$current_perms" != "$stored_perms" ]] || \
       [[ "$current_owner" != "$stored_owner" ]] || \
       [[ "$current_group" != "$stored_group" ]]; then
      permission_issues+="${file_path} (${current_perms} ${current_owner}:${current_group}), "
      issue_count=$((issue_count + 1))
      log_warn "Permission change: ${file_path}"
    fi
  done < "${INTEGRITY_CHECKSUM_FILE}"
  
  # Remove trailing comma
  permission_issues=${permission_issues%, }
  
  local status
  local message
  if [[ "$issue_count" -gt 0 ]]; then
    status="$STATUS_WARNING"
    message="Permission changes detected: ${permission_issues}"
    report=$(add_alert "$report" "warning" "integrity.permissions" "$message")
  else
    status="$STATUS_HEALTHY"
    message="All file permissions are correct"
  fi
  
  report=$(add_check "$report" "integrity.permissions" "File Permissions" "$status" "$message" "$issue_count")
  
  echo "$report"
}

check_recent_modifications() {
  local report="$1"
  
  log_debug "Checking recent file modifications..."
  
  if [[ ! -f "${INTEGRITY_CHECKSUM_FILE}" ]]; then
    echo "$report"
    return
  fi
  
  # Get current time
  local current_time
  current_time=$(date +%s)
  
  # Time threshold: 24 hours
  local time_threshold=$((24 * 60 * 60))
  
  local recent_modifications=""
  local recent_count=0
  
  while IFS='|' read -r file_path stored_checksum stored_perms stored_owner stored_group stored_mtime; do
    if [[ ! -f "$file_path" ]]; then
      continue
    fi
    
    local current_mtime
    current_mtime=$(stat -c "%Y" "$file_path" 2>/dev/null || stat -f "%m" "$file_path" 2>/dev/null)
    
    local time_diff=$((current_time - current_mtime))
    
    if [[ "$time_diff" -lt "$time_threshold" ]]; then
      recent_modifications+="${file_path}, "
      recent_count=$((recent_count + 1))
    fi
  done < "${INTEGRITY_CHECKSUM_FILE}"
  
  # Remove trailing comma
  recent_modifications=${recent_modifications%, }
  
  local status
  local message
  if [[ "$recent_count" -gt 0 ]]; then
    status="$STATUS_WARNING"
    message="File(s) modified in last 24h: ${recent_modifications}"
  else
    status="$STATUS_HEALTHY"
    message="No recent modifications to monitored files"
  fi
  
  report=$(add_check "$report" "integrity.recent_changes" "Recent Modifications" "$status" "$message" "$recent_count")
  
  echo "$report"
}

# ============================================================================
# Critical System Files Check
# ============================================================================

check_critical_system_files() {
  local report="$1"
  
  log_debug "Checking critical system files..."
  
  # List of critical files that must exist
  local critical_files=(
    "/etc/passwd"
    "/etc/group"
    "/etc/shadow"
    "/etc/ssh/sshd_config"
  )
  
  local missing_files=""
  local missing_count=0
  
  for file_path in "${critical_files[@]}"; do
    if [[ ! -f "$file_path" ]]; then
      missing_files+="${file_path}, "
      missing_count=$((missing_count + 1))
      log_error "Critical file missing: ${file_path}"
    fi
  done
  
  # Remove trailing comma
  missing_files=${missing_files%, }
  
  local status
  local message
  if [[ "$missing_count" -gt 0 ]]; then
    status="$STATUS_CRITICAL"
    message="Critical system file(s) missing: ${missing_files}"
    report=$(add_alert "$report" "critical" "integrity.critical_files" "$message")
  else
    status="$STATUS_HEALTHY"
    message="All critical system files exist"
  fi
  
  report=$(add_check "$report" "integrity.critical_files" "Critical System Files" "$status" "$message")
  
  echo "$report"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
  log_info "Starting integrity surveillance module v${MODULE_VERSION}"
  
  local start_time
  start_time=$(get_time_ms)
  
  # Parse arguments
  local config_file=""
  local init_mode=false
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --config)
        config_file="$2"
        shift 2
        ;;
      --init)
        init_mode=true
        shift
        ;;
      --help|-h)
        cat <<EOF
LexOrbital File Integrity Surveillance Module

Usage: $0 [options]

Options:
  --config PATH    Path to configuration file
  --init           Initialize checksum database
  --help, -h       Show this help message

Checks:
  - File checksums (integrity)
  - File permissions and ownership
  - Recent file modifications
  - Critical system files existence

First Run:
  Run with --init to initialize the checksum database:
    $0 --init

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
  
  # Initialize mode
  if [[ "$init_mode" == true ]]; then
    initialize_checksums
    exit 0
  fi
  
  # Initialize report
  local report
  report=$(init_report "$MODULE_NAME")
  
  # Perform checks
  report=$(check_file_checksums "$report")
  report=$(check_file_permissions "$report")
  report=$(check_recent_modifications "$report")
  report=$(check_critical_system_files "$report")
  
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
  
  log_info "Integrity surveillance completed in ${exec_time}ms with status: ${worst_status}"
  
  # Exit with appropriate code
  case "$worst_status" in
    "$STATUS_CRITICAL") exit 2 ;;
    "$STATUS_WARNING") exit 1 ;;
    *) exit 0 ;;
  esac
}

# Run main function
main "$@"

