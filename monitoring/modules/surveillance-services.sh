#!/usr/bin/env bash
# ============================================================================
# LexOrbital Services Surveillance Module
# ============================================================================
# Monitors services: systemd units, Docker containers, critical errors
#
# Usage: ./surveillance-services.sh [--config /path/to/config]
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

readonly MODULE_NAME="services"
readonly MODULE_VERSION="1.0.0"

# Default thresholds
THRESHOLD_JOURNAL_ERRORS_WARNING="${THRESHOLD_JOURNAL_ERRORS_WARNING:-5}"
THRESHOLD_JOURNAL_ERRORS_CRITICAL="${THRESHOLD_JOURNAL_ERRORS_CRITICAL:-20}"
THRESHOLD_FAILED_UNITS_WARNING="${THRESHOLD_FAILED_UNITS_WARNING:-1}"
THRESHOLD_FAILED_UNITS_CRITICAL="${THRESHOLD_FAILED_UNITS_CRITICAL:-3}"

# Time window for analysis (hours)
readonly ANALYSIS_WINDOW_HOURS=1

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
# Journal Monitoring
# ============================================================================

check_journal_critical_errors() {
  local report="$1"
  
  log_debug "Checking journal for critical errors..."
  
  # Get critical errors (priority 0-3: emerg, alert, crit, err)
  local error_count
  error_count=$(journalctl -p 3 --since "${ANALYSIS_WINDOW_HOURS} hour ago" --no-pager 2>/dev/null | \
    grep -v "^-- Logs begin" | grep -v "^-- No entries" | wc -l || echo "0")
  error_count=${error_count## }
  
  local status
  status=$(determine_status "$error_count" "$THRESHOLD_JOURNAL_ERRORS_WARNING" "$THRESHOLD_JOURNAL_ERRORS_CRITICAL" "gt")
  
  local message
  case "$status" in
    "$STATUS_CRITICAL")
      message="Critical: ${error_count} critical error(s) in journal (last ${ANALYSIS_WINDOW_HOURS}h)"
      ;;
    "$STATUS_WARNING")
      message="Warning: ${error_count} critical error(s) in journal (last ${ANALYSIS_WINDOW_HOURS}h)"
      ;;
    *)
      message="${error_count} critical error(s) in journal (last ${ANALYSIS_WINDOW_HOURS}h)"
      ;;
  esac
  
  report=$(add_check "$report" "journal.errors" "Journal Critical Errors" "$status" "$message" \
    "$error_count" "$THRESHOLD_JOURNAL_ERRORS_WARNING" "$THRESHOLD_JOURNAL_ERRORS_CRITICAL")
  
  # If critical, add sample of errors to alert
  if [[ "$status" == "$STATUS_CRITICAL" ]]; then
    local sample_errors
    sample_errors=$(journalctl -p 3 --since "${ANALYSIS_WINDOW_HOURS} hour ago" --no-pager -n 3 2>/dev/null | \
      grep -v "^-- Logs begin" | tail -n 3 | tr '\n' '; ' || echo "")
    
    if [[ -n "$sample_errors" ]]; then
      report=$(add_alert "$report" "critical" "journal.errors" "Recent critical errors: ${sample_errors}")
    fi
  fi
  
  echo "$report"
}

check_journal_by_priority() {
  local report="$1"
  
  log_debug "Analyzing journal by priority..."
  
  # Count errors by priority
  local emerg_count alert_count crit_count err_count
  
  emerg_count=$(journalctl -p 0 --since "${ANALYSIS_WINDOW_HOURS} hour ago" --no-pager 2>/dev/null | \
    grep -v "^-- Logs begin" | grep -v "^-- No entries" | wc -l || echo "0")
  alert_count=$(journalctl -p 1 --since "${ANALYSIS_WINDOW_HOURS} hour ago" --no-pager 2>/dev/null | \
    grep -v "^-- Logs begin" | grep -v "^-- No entries" | wc -l || echo "0")
  crit_count=$(journalctl -p 2 --since "${ANALYSIS_WINDOW_HOURS} hour ago" --no-pager 2>/dev/null | \
    grep -v "^-- Logs begin" | grep -v "^-- No entries" | wc -l || echo "0")
  err_count=$(journalctl -p 3 --since "${ANALYSIS_WINDOW_HOURS} hour ago" --no-pager 2>/dev/null | \
    grep -v "^-- Logs begin" | grep -v "^-- No entries" | wc -l || echo "0")
  
  emerg_count=${emerg_count## }
  alert_count=${alert_count## }
  crit_count=${crit_count## }
  err_count=${err_count## }
  
  local message
  message="Journal errors by priority: emerg=${emerg_count}, alert=${alert_count}, crit=${crit_count}, err=${err_count}"
  
  local status="$STATUS_HEALTHY"
  if [[ "$emerg_count" -gt 0 ]] || [[ "$alert_count" -gt 0 ]]; then
    status="$STATUS_CRITICAL"
  elif [[ "$crit_count" -gt 5 ]]; then
    status="$STATUS_WARNING"
  fi
  
  report=$(add_check "$report" "journal.priority" "Journal Error Breakdown" "$status" "$message")
  
  echo "$report"
}

# ============================================================================
# Systemd Unit Monitoring
# ============================================================================

check_failed_units() {
  local report="$1"
  
  log_debug "Checking for failed systemd units..."
  
  # Get list of failed units
  local failed_units
  failed_units=$(systemctl --failed --no-pager --no-legend 2>/dev/null | awk '{print $1}' | tr '\n' ', ' | sed 's/,$//' || echo "")
  
  local failed_count
  if [[ -n "$failed_units" ]]; then
    failed_count=$(echo "$failed_units" | tr ',' '\n' | wc -l)
  else
    failed_count=0
  fi
  
  local status
  status=$(determine_status "$failed_count" "$THRESHOLD_FAILED_UNITS_WARNING" "$THRESHOLD_FAILED_UNITS_CRITICAL" "gt")
  
  local message
  if [[ "$failed_count" -gt 0 ]]; then
    message="Failed systemd units: ${failed_units}"
    report=$(add_alert "$report" "warning" "systemd.failed_units" "$message")
  else
    message="No failed systemd units"
  fi
  
  report=$(add_check "$report" "systemd.failed_units" "Failed Systemd Units" "$status" "$message" \
    "$failed_count" "$THRESHOLD_FAILED_UNITS_WARNING" "$THRESHOLD_FAILED_UNITS_CRITICAL")
  
  echo "$report"
}

check_critical_services() {
  local report="$1"
  
  log_debug "Checking critical services status..."
  
  # List of critical services to monitor
  local critical_services=("sshd" "docker" "nginx")
  local down_services=""
  local down_count=0
  
  for service in "${critical_services[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
      log_debug "Service ${service} is active"
    else
      # Check if service exists before reporting as down
      if systemctl list-unit-files | grep -q "^${service}.service"; then
        down_services+="${service}, "
        down_count=$((down_count + 1))
      fi
    fi
  done
  
  # Remove trailing comma
  down_services=${down_services%, }
  
  local status
  local message
  if [[ "$down_count" -gt 0 ]]; then
    status="$STATUS_CRITICAL"
    message="Critical service(s) down: ${down_services}"
    report=$(add_alert "$report" "critical" "systemd.critical_services" "$message")
  else
    status="$STATUS_HEALTHY"
    message="All critical services are running"
  fi
  
  report=$(add_check "$report" "systemd.critical_services" "Critical Services Status" "$status" "$message")
  
  echo "$report"
}

# ============================================================================
# Docker Monitoring
# ============================================================================

check_docker_status() {
  local report="$1"
  
  log_debug "Checking Docker status..."
  
  # Check if Docker is installed and running
  if ! command -v docker &>/dev/null; then
    report=$(add_check "$report" "docker.status" "Docker Status" "$STATUS_UNKNOWN" \
      "Docker is not installed")
    echo "$report"
    return
  fi
  
  if ! docker info &>/dev/null; then
    report=$(add_check "$report" "docker.status" "Docker Status" "$STATUS_CRITICAL" \
      "Docker daemon is not running")
    report=$(add_alert "$report" "critical" "docker.status" "Docker daemon is not running")
    echo "$report"
    return
  fi
  
  report=$(add_check "$report" "docker.status" "Docker Status" "$STATUS_HEALTHY" \
    "Docker daemon is running")
  
  echo "$report"
}

check_docker_containers() {
  local report="$1"
  
  log_debug "Checking Docker containers..."
  
  if ! command -v docker &>/dev/null || ! docker info &>/dev/null; then
    echo "$report"
    return
  fi
  
  # Get container stats
  local total_containers running_containers stopped_containers
  total_containers=$(docker ps -a --format "{{.ID}}" 2>/dev/null | wc -l || echo "0")
  running_containers=$(docker ps --format "{{.ID}}" 2>/dev/null | wc -l || echo "0")
  stopped_containers=$((total_containers - running_containers))
  
  total_containers=${total_containers## }
  running_containers=${running_containers## }
  stopped_containers=${stopped_containers## }
  
  local status
  local message
  if [[ "$stopped_containers" -gt 0 ]]; then
    status="$STATUS_WARNING"
    message="Docker: ${running_containers}/${total_containers} containers running (${stopped_containers} stopped)"
  else
    status="$STATUS_HEALTHY"
    message="Docker: ${running_containers} container(s) running"
  fi
  
  report=$(add_check "$report" "docker.containers" "Docker Containers" "$status" "$message")
  
  echo "$report"
}

check_docker_health() {
  local report="$1"
  
  log_debug "Checking Docker container health..."
  
  if ! command -v docker &>/dev/null || ! docker info &>/dev/null; then
    echo "$report"
    return
  fi
  
  # Check for unhealthy containers
  local unhealthy_containers
  unhealthy_containers=$(docker ps --filter "health=unhealthy" --format "{{.Names}}" 2>/dev/null | tr '\n' ', ' | sed 's/,$//' || echo "")
  
  local unhealthy_count
  if [[ -n "$unhealthy_containers" ]]; then
    unhealthy_count=$(echo "$unhealthy_containers" | tr ',' '\n' | wc -l)
  else
    unhealthy_count=0
  fi
  
  local status
  local message
  if [[ "$unhealthy_count" -gt 0 ]]; then
    status="$STATUS_CRITICAL"
    message="Unhealthy Docker container(s): ${unhealthy_containers}"
    report=$(add_alert "$report" "critical" "docker.health" "$message")
  else
    status="$STATUS_HEALTHY"
    message="All Docker containers are healthy"
  fi
  
  report=$(add_check "$report" "docker.health" "Docker Container Health" "$status" "$message")
  
  echo "$report"
}

# ============================================================================
# Nginx Monitoring
# ============================================================================

check_nginx_status() {
  local report="$1"
  
  log_debug "Checking Nginx status..."
  
  # Check if Nginx is installed
  if ! command -v nginx &>/dev/null; then
    report=$(add_check "$report" "nginx.status" "Nginx Status" "$STATUS_UNKNOWN" \
      "Nginx is not installed")
    echo "$report"
    return
  fi
  
  # Check if Nginx service is active
  if systemctl is-active --quiet nginx 2>/dev/null; then
    report=$(add_check "$report" "nginx.status" "Nginx Status" "$STATUS_HEALTHY" \
      "Nginx is running")
  else
    report=$(add_check "$report" "nginx.status" "Nginx Status" "$STATUS_CRITICAL" \
      "Nginx is not running")
    report=$(add_alert "$report" "critical" "nginx.status" "Nginx is not running")
  fi
  
  echo "$report"
}

check_nginx_errors() {
  local report="$1"
  
  log_debug "Checking Nginx errors..."
  
  if ! command -v nginx &>/dev/null; then
    echo "$report"
    return
  fi
  
  # Check Nginx error log
  local nginx_error_log="/var/log/nginx/error.log"
  
  if [[ ! -f "$nginx_error_log" ]]; then
    report=$(add_check "$report" "nginx.errors" "Nginx Errors" "$STATUS_UNKNOWN" \
      "Nginx error log not found")
    echo "$report"
    return
  fi
  
  # Count errors in the last hour
  local error_count
  local since_time
  since_time=$(date -d "${ANALYSIS_WINDOW_HOURS} hour ago" "+%Y/%m/%d %H:" 2>/dev/null || \
    date -v-${ANALYSIS_WINDOW_HOURS}H "+%Y/%m/%d %H:" 2>/dev/null || echo "")
  
  if [[ -n "$since_time" ]]; then
    error_count=$(grep -c "\[error\]" "$nginx_error_log" 2>/dev/null | tail -n 100 || echo "0")
  else
    error_count=$(tail -n 100 "$nginx_error_log" 2>/dev/null | grep -c "\[error\]" || echo "0")
  fi
  
  error_count=${error_count## }
  
  local status
  if [[ "$error_count" -gt 20 ]]; then
    status="$STATUS_WARNING"
  else
    status="$STATUS_HEALTHY"
  fi
  
  local message
  message="${error_count} error(s) in Nginx error log (last ${ANALYSIS_WINDOW_HOURS}h)"
  
  report=$(add_check "$report" "nginx.errors" "Nginx Errors" "$status" "$message" "$error_count")
  
  echo "$report"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
  log_info "Starting services surveillance module v${MODULE_VERSION}"
  
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
LexOrbital Services Surveillance Module

Usage: $0 [options]

Options:
  --config PATH    Path to configuration file
  --help, -h       Show this help message

Checks:
  - Journal critical errors
  - Failed systemd units
  - Critical services status
  - Docker status and health
  - Nginx status and errors

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
  report=$(check_journal_critical_errors "$report")
  report=$(check_journal_by_priority "$report")
  report=$(check_failed_units "$report")
  report=$(check_critical_services "$report")
  report=$(check_docker_status "$report")
  report=$(check_docker_containers "$report")
  report=$(check_docker_health "$report")
  report=$(check_nginx_status "$report")
  report=$(check_nginx_errors "$report")
  
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
  
  log_info "Services surveillance completed in ${exec_time}ms with status: ${worst_status}"
  
  # Exit with appropriate code
  case "$worst_status" in
    "$STATUS_CRITICAL") exit 2 ;;
    "$STATUS_WARNING") exit 1 ;;
    *) exit 0 ;;
  esac
}

# Run main function
main "$@"

