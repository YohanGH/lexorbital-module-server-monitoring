#!/usr/bin/env bash
# ============================================================================
# LexOrbital Network Surveillance Module
# ============================================================================
# Monitors network: open ports, connections, firewall status
#
# Usage: ./surveillance-network.sh [--config /path/to/config]
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

readonly MODULE_NAME="network"
readonly MODULE_VERSION="1.0.0"

# Default configuration
NETWORK_ALLOWED_PORTS="${NETWORK_ALLOWED_PORTS:-22,80,443}"
THRESHOLD_UNEXPECTED_PORTS_WARNING="${THRESHOLD_UNEXPECTED_PORTS_WARNING:-1}"
THRESHOLD_UNEXPECTED_PORTS_CRITICAL="${THRESHOLD_UNEXPECTED_PORTS_CRITICAL:-3}"

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
# Port Monitoring
# ============================================================================

check_open_ports() {
  local report="$1"
  
  log_debug "Checking open ports..."
  
  # Get list of open ports using ss (modern replacement for netstat)
  local open_ports
  open_ports=$(ss -tuln 2>/dev/null | awk 'NR>1 {print $5}' | grep -oE ':[0-9]+$' | sed 's/://' | sort -nu | tr '\n' ',' | sed 's/,$//' || echo "")
  
  # Fallback to netstat if ss is not available
  if [[ -z "$open_ports" ]] && command -v netstat &>/dev/null; then
    open_ports=$(netstat -tuln 2>/dev/null | awk 'NR>2 {print $4}' | grep -oE ':[0-9]+$' | sed 's/://' | sort -nu | tr '\n' ',' | sed 's/,$//' || echo "")
  fi
  
  local port_count
  if [[ -n "$open_ports" ]]; then
    port_count=$(echo "$open_ports" | tr ',' '\n' | wc -l)
  else
    port_count=0
  fi
  
  local message
  message="${port_count} open port(s): ${open_ports}"
  
  report=$(add_check "$report" "network.open_ports" "Open Ports" "$STATUS_HEALTHY" "$message" "$port_count")
  
  echo "$report"
}

check_unexpected_ports() {
  local report="$1"
  
  log_debug "Checking for unexpected open ports..."
  
  # Get open ports
  local open_ports
  open_ports=$(ss -tuln 2>/dev/null | awk 'NR>1 {print $5}' | grep -oE ':[0-9]+$' | sed 's/://' | sort -nu || echo "")
  
  if [[ -z "$open_ports" ]]; then
    echo "$report"
    return
  fi
  
  # Convert allowed ports to array
  IFS=',' read -ra ALLOWED_PORTS <<< "$NETWORK_ALLOWED_PORTS"
  
  # Find unexpected ports
  local unexpected_ports=""
  local unexpected_count=0
  
  while read -r port; do
    [[ -z "$port" ]] && continue
    
    local is_allowed=false
    for allowed in "${ALLOWED_PORTS[@]}"; do
      if [[ "$port" == "$allowed" ]]; then
        is_allowed=true
        break
      fi
    done
    
    if [[ "$is_allowed" == false ]]; then
      unexpected_ports+="${port}, "
      unexpected_count=$((unexpected_count + 1))
    fi
  done <<< "$open_ports"
  
  # Remove trailing comma
  unexpected_ports=${unexpected_ports%, }
  
  local status
  status=$(determine_status "$unexpected_count" "$THRESHOLD_UNEXPECTED_PORTS_WARNING" "$THRESHOLD_UNEXPECTED_PORTS_CRITICAL" "gt")
  
  local message
  if [[ "$unexpected_count" -gt 0 ]]; then
    message="Unexpected open port(s): ${unexpected_ports}"
    if [[ "$status" == "$STATUS_CRITICAL" ]]; then
      report=$(add_alert "$report" "critical" "network.unexpected_ports" "$message")
    fi
  else
    message="No unexpected open ports"
  fi
  
  report=$(add_check "$report" "network.unexpected_ports" "Unexpected Ports" "$status" "$message" \
    "$unexpected_count" "$THRESHOLD_UNEXPECTED_PORTS_WARNING" "$THRESHOLD_UNEXPECTED_PORTS_CRITICAL")
  
  echo "$report"
}

# ============================================================================
# Connection Monitoring
# ============================================================================

check_established_connections() {
  local report="$1"
  
  log_debug "Checking established connections..."
  
  # Count established connections
  local conn_count
  conn_count=$(ss -tn state established 2>/dev/null | grep -c ESTAB || echo "0")
  conn_count=${conn_count## }
  
  local message
  message="${conn_count} established connection(s)"
  
  local status="$STATUS_HEALTHY"
  if [[ "$conn_count" -gt 100 ]]; then
    status="$STATUS_WARNING"
  fi
  
  report=$(add_check "$report" "network.established" "Established Connections" "$status" "$message" "$conn_count")
  
  echo "$report"
}

check_listening_services() {
  local report="$1"
  
  log_debug "Checking listening services..."
  
  # Get listening services with process names
  local temp_file
  temp_file=$(mktemp)
  
  ss -tlnp 2>/dev/null | awk 'NR>1 {
    port=$4; 
    gsub(/.*:/, "", port); 
    process=$NF; 
    gsub(/.*"/, "", process); 
    gsub(/".*/, "", process); 
    print port, process
  }' | sort -nu > "$temp_file" || true
  
  local service_count
  service_count=$(wc -l < "$temp_file" || echo "0")
  service_count=${service_count## }
  
  local message
  message="${service_count} service(s) listening for connections"
  
  report=$(add_check "$report" "network.listening" "Listening Services" "$STATUS_HEALTHY" "$message" "$service_count")
  
  rm -f "$temp_file"
  
  echo "$report"
}

# ============================================================================
# Firewall Monitoring
# ============================================================================

check_firewall_status() {
  local report="$1"
  
  log_debug "Checking firewall status..."
  
  # Check UFW status
  if command -v ufw &>/dev/null; then
    local ufw_status
    ufw_status=$(ufw status 2>/dev/null | head -n 1 || echo "Status: unknown")
    
    local status
    local message
    if echo "$ufw_status" | grep -qi "active"; then
      status="$STATUS_HEALTHY"
      message="UFW firewall is active"
    else
      status="$STATUS_WARNING"
      message="UFW firewall is not active"
      report=$(add_alert "$report" "warning" "firewall.ufw" "UFW firewall is not active")
    fi
    
    report=$(add_check "$report" "firewall.ufw" "UFW Firewall Status" "$status" "$message")
  
  # Check iptables if UFW is not available
  elif command -v iptables &>/dev/null; then
    local rule_count
    rule_count=$(iptables -L -n 2>/dev/null | grep -c "^Chain\|^target" || echo "0")
    
    local status
    local message
    if [[ "$rule_count" -gt 5 ]]; then
      status="$STATUS_HEALTHY"
      message="iptables firewall is configured (${rule_count} rules)"
    else
      status="$STATUS_WARNING"
      message="iptables firewall has minimal configuration"
    fi
    
    report=$(add_check "$report" "firewall.iptables" "iptables Firewall" "$status" "$message")
  
  else
    report=$(add_check "$report" "firewall.status" "Firewall Status" "$STATUS_WARNING" \
      "No firewall detected (UFW or iptables)")
  fi
  
  echo "$report"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
  log_info "Starting network surveillance module v${MODULE_VERSION}"
  
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
LexOrbital Network Surveillance Module

Usage: $0 [options]

Options:
  --config PATH    Path to configuration file
  --help, -h       Show this help message

Checks:
  - Open ports
  - Unexpected ports
  - Established connections
  - Listening services
  - Firewall status

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
  report=$(check_open_ports "$report")
  report=$(check_unexpected_ports "$report")
  report=$(check_established_connections "$report")
  report=$(check_listening_services "$report")
  report=$(check_firewall_status "$report")
  
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
  
  log_info "Network surveillance completed in ${exec_time}ms with status: ${worst_status}"
  
  # Exit with appropriate code
  case "$worst_status" in
    "$STATUS_CRITICAL") exit 2 ;;
    "$STATUS_WARNING") exit 1 ;;
    *) exit 0 ;;
  esac
}

# Run main function
main "$@"

