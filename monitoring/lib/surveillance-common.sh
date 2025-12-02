#!/usr/bin/env bash
# ============================================================================
# LexOrbital Surveillance Common Library
# ============================================================================
# Shared functions and utilities for all surveillance modules
#
# Usage: source ./lib/surveillance-common.sh
# ============================================================================

set -euo pipefail

# ============================================================================
# Constants
# ============================================================================

readonly SURVEILLANCE_VERSION="1.0.0"
readonly SURVEILLANCE_DIR="${SURVEILLANCE_DIR:-/var/lib/lexorbital/surveillance}"
readonly SURVEILLANCE_REPORTS_DIR="${SURVEILLANCE_DIR}/reports"
readonly SURVEILLANCE_CONFIG_DIR="${SURVEILLANCE_DIR}/config"
readonly SURVEILLANCE_LOG_FILE="${SURVEILLANCE_LOG_FILE:-/var/log/lexorbital/surveillance.log}"

# Colors for output
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_NC='\033[0m' # No Color

# Health status values
readonly STATUS_HEALTHY="healthy"
readonly STATUS_WARNING="warning"
readonly STATUS_CRITICAL="critical"
readonly STATUS_UNKNOWN="unknown"

# ============================================================================
# Logging Functions
# ============================================================================

# Log message to file and optionally to stdout
# Arguments:
#   $1 - Log level (INFO, WARN, ERROR, DEBUG)
#   $2 - Message
log_message() {
  local level="${1:-INFO}"
  local message="${2:-}"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  local log_entry="[${timestamp}] [${level}] ${message}"
  
  # Create log directory if it doesn't exist
  mkdir -p "$(dirname "${SURVEILLANCE_LOG_FILE}")" 2>/dev/null || true
  
  # Write to log file
  echo "${log_entry}" >> "${SURVEILLANCE_LOG_FILE}" 2>/dev/null || true
  
  # Optionally write to stdout for DEBUG
  if [[ "${SURVEILLANCE_DEBUG:-false}" == "true" ]]; then
    echo "${log_entry}" >&2
  fi
}

# Convenience logging functions
log_info() {
  log_message "INFO" "$1"
}

log_warn() {
  log_message "WARN" "$1"
}

log_error() {
  log_message "ERROR" "$1"
}

log_debug() {
  if [[ "${SURVEILLANCE_DEBUG:-false}" == "true" ]]; then
    log_message "DEBUG" "$1"
  fi
}

# ============================================================================
# Output Functions (for human-readable output)
# ============================================================================

print_success() {
  echo -e "${COLOR_GREEN}✅ $1${COLOR_NC}"
}

print_warning() {
  echo -e "${COLOR_YELLOW}⚠️  $1${COLOR_NC}"
}

print_error() {
  echo -e "${COLOR_RED}❌ $1${COLOR_NC}" >&2
}

print_info() {
  echo -e "${COLOR_BLUE}ℹ️  $1${COLOR_NC}"
}

# ============================================================================
# JSON Utilities
# ============================================================================

# Escape string for JSON
# Arguments:
#   $1 - String to escape
json_escape() {
  local string="${1:-}"
  # Escape backslashes, quotes, and control characters
  printf '%s' "$string" | jq -Rsa .
}

# Check if jq is available
require_jq() {
  if ! command -v jq &> /dev/null; then
    print_error "jq is required but not installed"
    log_error "jq is required but not installed"
    exit 1
  fi
}

# Validate JSON against schema (requires ajv-cli)
# Arguments:
#   $1 - JSON file path
#   $2 - Schema file path (optional)
validate_json() {
  local json_file="$1"
  local schema_file="${2:-}"
  
  require_jq
  
  # Basic JSON validation
  if ! jq empty "$json_file" 2>/dev/null; then
    log_error "Invalid JSON in file: ${json_file}"
    return 1
  fi
  
  # Schema validation if ajv is available and schema provided
  if [[ -n "$schema_file" ]] && command -v ajv &> /dev/null; then
    if ! ajv validate -s "$schema_file" -d "$json_file" 2>/dev/null; then
      log_error "JSON schema validation failed for: ${json_file}"
      return 1
    fi
  fi
  
  return 0
}

# ============================================================================
# GDPR Utilities
# ============================================================================

# Pseudonymize IP address (GDPR Article 32)
# Arguments:
#   $1 - IP address
# Returns:
#   Pseudonymized IP (e.g., 192.168.xxx.xxx)
pseudonymize_ip() {
  local ip="${1:-}"
  
  if [[ -z "$ip" ]]; then
    echo "unknown"
    return
  fi
  
  # IPv4: Keep first two octets, mask last two
  if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    echo "$ip" | sed -E 's/([0-9]+\.[0-9]+)\.[0-9]+\.[0-9]+/\1.xxx.xxx/'
    return
  fi
  
  # IPv6: Keep first 4 groups, mask the rest
  if [[ "$ip" =~ : ]]; then
    echo "$ip" | sed -E 's/^([0-9a-fA-F:]+:){4}.*/\1xxxx:xxxx:xxxx:xxxx/'
    return
  fi
  
  # Unknown format
  echo "xxx.xxx.xxx.xxx"
}

# Pseudonymize username (keep first 2 chars + hash)
# Arguments:
#   $1 - Username
# Returns:
#   Pseudonymized username
pseudonymize_username() {
  local username="${1:-}"
  
  if [[ -z "$username" ]]; then
    echo "unknown"
    return
  fi
  
  # Keep first 2 characters + short hash
  local prefix="${username:0:2}"
  local hash
  hash=$(echo -n "$username" | sha256sum | cut -c1-8)
  
  echo "${prefix}***${hash}"
}

# Check if GDPR pseudonymization is enabled
is_gdpr_enabled() {
  local config_file="${SURVEILLANCE_CONFIG_DIR}/surveillance.conf"
  
  if [[ -f "$config_file" ]]; then
    local gdpr_enabled
    gdpr_enabled=$(grep -E "^GDPR_PSEUDONYMIZE_IPS=" "$config_file" | cut -d'=' -f2)
    [[ "$gdpr_enabled" == "true" ]]
  else
    # Default: enabled
    return 0
  fi
}

# ============================================================================
# Status Evaluation
# ============================================================================

# Determine status based on value and thresholds
# Arguments:
#   $1 - Value
#   $2 - Warning threshold
#   $3 - Critical threshold
#   $4 - Comparison mode (default: "gt" for greater-than, "lt" for less-than)
# Returns:
#   Status: healthy, warning, critical
determine_status() {
  local value="${1:-0}"
  local warning="${2:-70}"
  local critical="${3:-85}"
  local mode="${4:-gt}" # gt = greater-than, lt = less-than
  
  # Remove % sign if present
  value="${value%\%}"
  
  # Convert to integer for comparison
  value=$(printf "%.0f" "$value" 2>/dev/null || echo "0")
  warning=$(printf "%.0f" "$warning" 2>/dev/null || echo "70")
  critical=$(printf "%.0f" "$critical" 2>/dev/null || echo "85")
  
  if [[ "$mode" == "gt" ]]; then
    if (( value >= critical )); then
      echo "$STATUS_CRITICAL"
    elif (( value >= warning )); then
      echo "$STATUS_WARNING"
    else
      echo "$STATUS_HEALTHY"
    fi
  else
    # less-than mode (useful for available resources)
    if (( value <= critical )); then
      echo "$STATUS_CRITICAL"
    elif (( value <= warning )); then
      echo "$STATUS_WARNING"
    else
      echo "$STATUS_HEALTHY"
    fi
  fi
}

# Get worst status from a list of statuses
# Arguments:
#   $@ - List of statuses
# Returns:
#   Worst status (critical > warning > unknown > healthy)
get_worst_status() {
  local worst="$STATUS_HEALTHY"
  
  for status in "$@"; do
    case "$status" in
      "$STATUS_CRITICAL")
        worst="$STATUS_CRITICAL"
        break
        ;;
      "$STATUS_WARNING")
        if [[ "$worst" != "$STATUS_CRITICAL" ]]; then
          worst="$STATUS_WARNING"
        fi
        ;;
      "$STATUS_UNKNOWN")
        if [[ "$worst" == "$STATUS_HEALTHY" ]]; then
          worst="$STATUS_UNKNOWN"
        fi
        ;;
    esac
  done
  
  echo "$worst"
}

# ============================================================================
# JSON Report Building
# ============================================================================

# Initialize JSON report structure
# Arguments:
#   $1 - Module name
# Outputs:
#   JSON string
init_report() {
  local module="$1"
  local timestamp
  local hostname
  
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  hostname=$(hostname -f 2>/dev/null || hostname)
  
  cat <<EOF
{
  "metadata": {
    "module": "${module}",
    "version": "${SURVEILLANCE_VERSION}",
    "timestamp": "${timestamp}",
    "hostname": "${hostname}",
    "executionTime": 0
  },
  "status": "${STATUS_UNKNOWN}",
  "checks": [],
  "metrics": {},
  "alerts": []
}
EOF
}

# Add check to report
# Arguments:
#   $1 - Report JSON (string)
#   $2 - Check ID
#   $3 - Check name
#   $4 - Status
#   $5 - Message
#   $6 - Value (optional)
#   $7 - Warning threshold (optional)
#   $8 - Critical threshold (optional)
add_check() {
  local report="$1"
  local check_id="$2"
  local check_name="$3"
  local status="$4"
  local message="$5"
  local value="${6:-}"
  local warning_threshold="${7:-}"
  local critical_threshold="${8:-}"
  
  require_jq
  
  # Build check object using jq for proper JSON construction
  local check_json
  check_json=$(jq -n \
    --arg id "$check_id" \
    --arg name "$check_name" \
    --arg status "$status" \
    --arg message "$message" \
    '{
      id: $id,
      name: $name,
      status: $status,
      message: $message
    }')
  
  # Add value if provided
  if [[ -n "$value" ]]; then
    # Detect if value is numeric
    if [[ "$value" =~ ^[0-9]+\.?[0-9]*$ ]]; then
      # Numeric value: use --arg and let jq convert to number
      check_json=$(echo "$check_json" | jq --arg val "$value" '. + {value: ($val | tonumber)}')
    else
      # String value: use --arg as-is
      check_json=$(echo "$check_json" | jq --arg val "$value" '. + {value: $val}')
    fi
  fi
  
  # Add threshold if provided
  if [[ -n "$warning_threshold" ]] && [[ -n "$critical_threshold" ]]; then
    # Thresholds are always numeric: use --arg and convert to number
    check_json=$(echo "$check_json" | jq \
      --arg warning "$warning_threshold" \
      --arg critical "$critical_threshold" \
      '. + {threshold: {warning: ($warning | tonumber), critical: ($critical | tonumber)}}')
  fi
  
  # Add check to report using --argjson to properly pass the JSON object
  echo "$report" | jq --argjson check "$check_json" '.checks += [$check]'
}

# Add alert to report
# Arguments:
#   $1 - Report JSON (string)
#   $2 - Severity (info, warning, critical)
#   $3 - Source
#   $4 - Message
add_alert() {
  local report="$1"
  local severity="$2"
  local source="$3"
  local message="$4"
  
  require_jq
  
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  local alert
  alert=$(cat <<EOF
{
  "severity": "${severity}",
  "source": "${source}",
  "message": $(json_escape "$message"),
  "timestamp": "${timestamp}"
}
EOF
)
  
  echo "$report" | jq ".alerts += [${alert}]"
}

# Update report status
# Arguments:
#   $1 - Report JSON (string)
#   $2 - Status
update_status() {
  local report="$1"
  local status="$2"
  
  require_jq
  echo "$report" | jq ".status = \"${status}\""
}

# Update execution time
# Arguments:
#   $1 - Report JSON (string)
#   $2 - Execution time in milliseconds
update_execution_time() {
  local report="$1"
  local exec_time="$2"
  
  require_jq
  echo "$report" | jq ".metadata.executionTime = ${exec_time}"
}

# ============================================================================
# File Operations
# ============================================================================

# Ensure surveillance directories exist
ensure_directories() {
  mkdir -p "${SURVEILLANCE_REPORTS_DIR}" 2>/dev/null || true
  mkdir -p "${SURVEILLANCE_CONFIG_DIR}" 2>/dev/null || true
  mkdir -p "$(dirname "${SURVEILLANCE_LOG_FILE}")" 2>/dev/null || true
  
  # Set secure permissions
  chmod 750 "${SURVEILLANCE_DIR}" 2>/dev/null || true
  chmod 750 "${SURVEILLANCE_REPORTS_DIR}" 2>/dev/null || true
  chmod 640 "${SURVEILLANCE_LOG_FILE}" 2>/dev/null || true
}

# Save report to file
# Arguments:
#   $1 - Report JSON (string)
#   $2 - Output file path
save_report() {
  local report="$1"
  local output_file="$2"
  
  ensure_directories
  
  # Save report
  echo "$report" | jq '.' > "$output_file" 2>/dev/null || {
    log_error "Failed to save report to ${output_file}"
    return 1
  }
  
  # Set secure permissions
  chmod 640 "$output_file" 2>/dev/null || true
  
  log_info "Report saved to ${output_file}"
}

# ============================================================================
# Time Measurement
# ============================================================================

# Get current time in milliseconds
get_time_ms() {
  date +%s%3N 2>/dev/null || echo "$(($(date +%s) * 1000))"
}

# ============================================================================
# Initialization
# ============================================================================

# Ensure directories exist on load
ensure_directories

log_debug "surveillance-common.sh loaded (version ${SURVEILLANCE_VERSION})"
