#!/usr/bin/env bash
# ============================================================================
# LexOrbital Surveillance Orchestrator
# ============================================================================
# Coordinates execution of all surveillance modules and generates global report
#
# Usage: ./surveillance-orchestrator.sh [--config /path/to/config] [--modules module1,module2]
# Output: Global JSON report
# ============================================================================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Determine common library path
# Try relative path first (development), then absolute path (installed)
if [[ -f "${SCRIPT_DIR}/../lib/surveillance-common.sh" ]]; then
  COMMON_LIB="${SCRIPT_DIR}/../lib/surveillance-common.sh"
elif [[ -f "/usr/local/lib/lexorbital/surveillance-common.sh" ]]; then
  COMMON_LIB="/usr/local/lib/lexorbital/surveillance-common.sh"
elif [[ -f "/opt/lexorbital/surveillance/lib/surveillance-common.sh" ]]; then
  COMMON_LIB="/opt/lexorbital/surveillance/lib/surveillance-common.sh"
elif [[ -n "${SURVEILLANCE_LIB_DIR:-}" ]] && [[ -f "${SURVEILLANCE_LIB_DIR}/surveillance-common.sh" ]]; then
  COMMON_LIB="${SURVEILLANCE_LIB_DIR}/surveillance-common.sh"
else
  echo "Error: surveillance-common.sh not found" >&2
  echo "Tried:" >&2
  echo "  ${SCRIPT_DIR}/../lib/surveillance-common.sh" >&2
  echo "  /usr/local/lib/lexorbital/surveillance-common.sh" >&2
  echo "  /opt/lexorbital/surveillance/lib/surveillance-common.sh" >&2
  if [[ -n "${SURVEILLANCE_LIB_DIR:-}" ]]; then
    echo "  ${SURVEILLANCE_LIB_DIR}/surveillance-common.sh" >&2
  fi
  exit 1
fi

# Load common library
# shellcheck source=../lib/surveillance-common.sh
source "$COMMON_LIB"

# ============================================================================
# Orchestrator Configuration
# ============================================================================

readonly ORCHESTRATOR_VERSION="1.0.0"
readonly MODULES_DIR="${SCRIPT_DIR}/../modules"

# Default modules to run
DEFAULT_MODULES="resources,security,services,network,integrity"

# Module configuration from config file
MODULE_RESOURCES_ENABLED="${MODULE_RESOURCES_ENABLED:-true}"
MODULE_SECURITY_ENABLED="${MODULE_SECURITY_ENABLED:-true}"
MODULE_SERVICES_ENABLED="${MODULE_SERVICES_ENABLED:-true}"
MODULE_NETWORK_ENABLED="${MODULE_NETWORK_ENABLED:-true}"
MODULE_INTEGRITY_ENABLED="${MODULE_INTEGRITY_ENABLED:-true}"

# Execution settings
PARALLEL_EXECUTION="${PARALLEL_EXECUTION:-true}"
MODULE_TIMEOUT="${MODULE_TIMEOUT:-60}"

# API settings
API_ENABLED="${API_ENABLED:-false}"
API_ENDPOINT="${API_ENDPOINT:-}"
API_TOKEN="${API_TOKEN:-}"
API_TIMEOUT="${API_TIMEOUT:-10}"

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
# Module Execution
# ============================================================================

run_module() {
  local module_name="$1"
  local module_script="${MODULES_DIR}/surveillance-${module_name}.sh"
  
  log_info "Running module: ${module_name}"
  
  # Check if module script exists
  if [[ ! -f "$module_script" ]]; then
    log_error "Module script not found: ${module_script}"
    return 1
  fi
  
  # Check if module is executable
  if [[ ! -x "$module_script" ]]; then
    log_error "Module script is not executable: ${module_script}"
    chmod +x "$module_script" 2>/dev/null || return 1
  fi
  
  # Run module with timeout
  local exit_code=0
  
  if command -v timeout &>/dev/null; then
    timeout "${MODULE_TIMEOUT}s" bash "$module_script" > /dev/null 2>&1 || exit_code=$?
  else
    bash "$module_script" > /dev/null 2>&1 || exit_code=$?
  fi
  
  # Check if report was generated
  local report_file="${SURVEILLANCE_REPORTS_DIR}/${module_name}.json"
  if [[ ! -f "$report_file" ]]; then
    log_error "Module ${module_name} did not generate a report"
    return 1
  fi
  
  # Validate JSON
  if ! jq empty "$report_file" 2>/dev/null; then
    log_error "Module ${module_name} generated invalid JSON"
    return 1
  fi
  
  log_info "Module ${module_name} completed with exit code ${exit_code}"
  return 0
}

run_modules_parallel() {
  local modules=("$@")
  
  log_info "Running ${#modules[@]} modules in parallel..."
  
  local pids=()
  local failed_modules=()
  
  # Start all modules in background
  for module in "${modules[@]}"; do
    run_module "$module" &
    pids+=($!)
  done
  
  # Wait for all modules to complete
  local index=0
  for pid in "${pids[@]}"; do
    if ! wait "$pid"; then
      failed_modules+=("${modules[$index]}")
    fi
    index=$((index + 1))
  done
  
  if [[ ${#failed_modules[@]} -gt 0 ]]; then
    log_warn "Failed modules: ${failed_modules[*]}"
  fi
  
  return ${#failed_modules[@]}
}

run_modules_sequential() {
  local modules=("$@")
  
  log_info "Running ${#modules[@]} modules sequentially..."
  
  local failed_count=0
  
  for module in "${modules[@]}"; do
    if ! run_module "$module"; then
      failed_count=$((failed_count + 1))
    fi
  done
  
  return "$failed_count"
}

# ============================================================================
# Report Aggregation
# ============================================================================

aggregate_reports() {
  local modules=("$@")
  
  log_debug "Aggregating reports from ${#modules[@]} modules..."
  
  require_jq
  
  local global_report
  local timestamp
  local hostname
  
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  hostname=$(hostname -f 2>/dev/null || hostname)
  
  # Initialize global report structure
  global_report=$(cat <<EOF
{
  "metadata": {
    "version": "${ORCHESTRATOR_VERSION}",
    "timestamp": "${timestamp}",
    "hostname": "${hostname}",
    "totalExecutionTime": 0,
    "modulesExecuted": ${#modules[@]},
    "modulesFailed": 0
  },
  "globalStatus": "unknown",
  "modules": {},
  "summary": {
    "totalChecks": 0,
    "healthyChecks": 0,
    "warningChecks": 0,
    "criticalChecks": 0,
    "unknownChecks": 0
  },
  "alerts": []
}
EOF
)
  
  local total_checks=0
  local healthy_checks=0
  local warning_checks=0
  local critical_checks=0
  local unknown_checks=0
  local modules_failed=0
  local all_statuses=()
  
  # Aggregate each module report
  for module in "${modules[@]}"; do
    local report_file="${SURVEILLANCE_REPORTS_DIR}/${module}.json"
    
    if [[ ! -f "$report_file" ]]; then
      log_warn "Report not found for module: ${module}"
      modules_failed=$((modules_failed + 1))
      continue
    fi
    
    # Read module report
    local module_report
    module_report=$(cat "$report_file")
    
    # Add module report to global report
    global_report=$(echo "$global_report" | jq ".modules.${module} = ${module_report}")
    
    # Extract module status
    local module_status
    module_status=$(echo "$module_report" | jq -r '.status')
    all_statuses+=("$module_status")
    
    # Aggregate checks
    local module_total module_healthy module_warning module_critical module_unknown
    module_total=$(echo "$module_report" | jq '[.checks[]] | length')
    module_healthy=$(echo "$module_report" | jq '[.checks[] | select(.status == "healthy")] | length')
    module_warning=$(echo "$module_report" | jq '[.checks[] | select(.status == "warning")] | length')
    module_critical=$(echo "$module_report" | jq '[.checks[] | select(.status == "critical")] | length')
    module_unknown=$(echo "$module_report" | jq '[.checks[] | select(.status == "unknown")] | length')
    
    total_checks=$((total_checks + module_total))
    healthy_checks=$((healthy_checks + module_healthy))
    warning_checks=$((warning_checks + module_warning))
    critical_checks=$((critical_checks + module_critical))
    unknown_checks=$((unknown_checks + module_unknown))
    
    # Aggregate alerts
    local module_alerts
    module_alerts=$(echo "$module_report" | jq -c '.alerts[]?' 2>/dev/null || echo "")
    
    if [[ -n "$module_alerts" ]]; then
      while IFS= read -r alert; do
        global_report=$(echo "$global_report" | jq ".alerts += [${alert}]")
      done <<< "$module_alerts"
    fi
  done
  
  # Calculate global status (worst-case)
  local global_status
  global_status=$(get_worst_status "${all_statuses[@]}")
  
  # Update summary
  global_report=$(echo "$global_report" | jq \
    ".summary.totalChecks = ${total_checks} | \
     .summary.healthyChecks = ${healthy_checks} | \
     .summary.warningChecks = ${warning_checks} | \
     .summary.criticalChecks = ${critical_checks} | \
     .summary.unknownChecks = ${unknown_checks} | \
     .globalStatus = \"${global_status}\" | \
     .metadata.modulesFailed = ${modules_failed}")
  
  echo "$global_report"
}

# ============================================================================
# API Integration
# ============================================================================

send_to_api() {
  local report="$1"
  
  if [[ "$API_ENABLED" != "true" ]]; then
    log_debug "API integration disabled"
    return 0
  fi
  
  if [[ -z "$API_ENDPOINT" ]]; then
    log_warn "API endpoint not configured"
    return 0
  fi
  
  log_info "Sending report to API: ${API_ENDPOINT}"
  
  # Prepare API request
  local response
  local http_code
  
  if command -v curl &>/dev/null; then
    response=$(curl -s -w "\n%{http_code}" \
      -X POST \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer ${API_TOKEN}" \
      --max-time "${API_TIMEOUT}" \
      -d "$report" \
      "${API_ENDPOINT}" 2>/dev/null || echo -e "\n000")
    
    http_code=$(echo "$response" | tail -n 1)
    
    if [[ "$http_code" == "200" ]] || [[ "$http_code" == "201" ]]; then
      log_info "Report successfully sent to API (HTTP ${http_code})"
      return 0
    else
      log_error "Failed to send report to API (HTTP ${http_code})"
      return 1
    fi
  else
    log_warn "curl not available, cannot send to API"
    return 1
  fi
}

# ============================================================================
# Alert Handling
# ============================================================================

send_email_alerts() {
  local report="$1"
  
  if [[ "${ALERT_EMAIL_ENABLED:-false}" != "true" ]]; then
    return 0
  fi
  
  # Extract critical alerts
  local critical_alerts
  critical_alerts=$(echo "$report" | jq -r '.alerts[] | select(.severity == "critical") | .message' 2>/dev/null || echo "")
  
  if [[ -z "$critical_alerts" ]]; then
    log_debug "No critical alerts to send"
    return 0
  fi
  
  log_info "Sending email alerts..."
  
  local hostname
  hostname=$(hostname -f 2>/dev/null || hostname)
  
  local email_body
  email_body=$(cat <<EOF
LexOrbital Surveillance Alert
=============================

Server: ${hostname}
Time: $(date)

Critical Alerts:
${critical_alerts}

---
This is an automated message from LexOrbital Surveillance System.
EOF
)

  # Send email (requires mail command)
  if command -v mail &>/dev/null; then
    echo "$email_body" | mail -s "[LexOrbital] Critical Surveillance Alert - ${hostname}" "${ALERT_EMAIL_RECIPIENTS}"
    log_info "Alert email sent to ${ALERT_EMAIL_RECIPIENTS}"
  else
    log_warn "mail command not available, cannot send email alerts"
  fi
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
  log_info "Starting LexOrbital Surveillance Orchestrator v${ORCHESTRATOR_VERSION}"
  
  print_info "🛰️  LexOrbital Surveillance Orchestrator v${ORCHESTRATOR_VERSION}"
  echo ""
  
  local start_time
  start_time=$(get_time_ms)
  
  # Parse arguments
  local config_file=""
  local modules_to_run=""
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --config)
        config_file="$2"
        shift 2
        ;;
      --modules)
        modules_to_run="$2"
        shift 2
        ;;
      --help|-h)
        cat <<EOF
LexOrbital Surveillance Orchestrator

Coordinates execution of all surveillance modules and generates a global report.

Usage: $0 [options]

Options:
  --config PATH          Path to configuration file
  --modules module1,...  Comma-separated list of modules to run
                         (default: all enabled modules)
  --help, -h             Show this help message

Available Modules:
  - resources   CPU, RAM, disk, I/O
  - security    SSH, brute-force, sudo
  - services    Systemd, Docker, Nginx
  - network     Ports, connections, firewall
  - integrity   File checksums, permissions

Output:
  Global JSON report in ${SURVEILLANCE_REPORTS_DIR}/global.json

Examples:
  # Run all modules
  $0

  # Run specific modules only
  $0 --modules resources,security

  # Use custom configuration
  $0 --config /etc/lexorbital/surveillance.conf
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
  
  # Determine which modules to run
  local modules=()
  
  if [[ -n "$modules_to_run" ]]; then
    # Use specified modules
    IFS=',' read -ra modules <<< "$modules_to_run"
  else
    # Use enabled modules from config
    [[ "$MODULE_RESOURCES_ENABLED" == "true" ]] && modules+=("resources")
    [[ "$MODULE_SECURITY_ENABLED" == "true" ]] && modules+=("security")
    [[ "$MODULE_SERVICES_ENABLED" == "true" ]] && modules+=("services")
    [[ "$MODULE_NETWORK_ENABLED" == "true" ]] && modules+=("network")
    [[ "$MODULE_INTEGRITY_ENABLED" == "true" ]] && modules+=("integrity")
  fi
  
  if [[ ${#modules[@]} -eq 0 ]]; then
    print_error "No modules enabled or specified"
    exit 1
  fi
  
  print_info "Running ${#modules[@]} module(s): ${modules[*]}"
  echo ""
  
  # Ensure directories exist
  ensure_directories
  
  # Run modules
  local failed_count
  if [[ "$PARALLEL_EXECUTION" == "true" ]]; then
    run_modules_parallel "${modules[@]}" || failed_count=$?
  else
    run_modules_sequential "${modules[@]}" || failed_count=$?
  fi
  
  echo ""
  print_info "Module execution completed (${failed_count:-0} failed)"
  echo ""
  
  # Aggregate reports
  print_info "Aggregating reports..."
  local global_report
  global_report=$(aggregate_reports "${modules[@]}")
  
  # Update total execution time
  local end_time exec_time
  end_time=$(get_time_ms)
  exec_time=$((end_time - start_time))
  global_report=$(echo "$global_report" | jq ".metadata.totalExecutionTime = ${exec_time}")
  
  # Save global report
  local global_output_file="${SURVEILLANCE_REPORTS_DIR}/global.json"
  save_report "$global_report" "$global_output_file"
  
  # Display summary
  echo ""
  print_info "📊 Surveillance Summary"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  local global_status
  global_status=$(echo "$global_report" | jq -r '.globalStatus')
  
  case "$global_status" in
    "$STATUS_HEALTHY")
      print_success "Global Status: HEALTHY ✅"
      ;;
    "$STATUS_WARNING")
      print_warning "Global Status: WARNING ⚠️"
      ;;
    "$STATUS_CRITICAL")
      print_error "Global Status: CRITICAL 🚨"
      ;;
    *)
      print_info "Global Status: UNKNOWN"
      ;;
  esac
  
  local total_checks healthy_checks warning_checks critical_checks
  total_checks=$(echo "$global_report" | jq -r '.summary.totalChecks')
  healthy_checks=$(echo "$global_report" | jq -r '.summary.healthyChecks')
  warning_checks=$(echo "$global_report" | jq -r '.summary.warningChecks')
  critical_checks=$(echo "$global_report" | jq -r '.summary.criticalChecks')
  
  echo ""
  echo "  Total Checks: ${total_checks}"
  echo "  ✅ Healthy:   ${healthy_checks}"
  echo "  ⚠️  Warning:   ${warning_checks}"
  echo "  🚨 Critical:  ${critical_checks}"
  echo ""
  echo "  Execution Time: ${exec_time}ms"
  echo "  Report: ${global_output_file}"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Send to API if enabled
  if [[ "$API_ENABLED" == "true" ]]; then
    echo ""
    print_info "Sending report to Console Orbitale..."
    send_to_api "$global_report" || true
  fi
  
  # Send email alerts if necessary
  if [[ "$critical_checks" -gt 0 ]]; then
    send_email_alerts "$global_report" || true
  fi
  
  echo ""
  log_info "Surveillance orchestrator completed in ${exec_time}ms with status: ${global_status}"
  
  # Exit with appropriate code
  case "$global_status" in
    "$STATUS_CRITICAL") exit 2 ;;
    "$STATUS_WARNING") exit 1 ;;
    *) exit 0 ;;
  esac
}

# Run main function
main "$@"

