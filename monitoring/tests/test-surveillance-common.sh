#!/usr/bin/env bash
# ============================================================================
# Tests for surveillance-common.sh library
# ============================================================================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load library
source "${SCRIPT_DIR}/../lib/surveillance-common.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================================
# Test Framework
# ============================================================================

assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  if [[ "$expected" == "$actual" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "✅ PASS: ${test_name}"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "❌ FAIL: ${test_name}"
    echo "   Expected: ${expected}"
    echo "   Actual:   ${actual}"
  fi
}

assert_not_empty() {
  local value="$1"
  local test_name="$2"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  if [[ -n "$value" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "✅ PASS: ${test_name}"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "❌ FAIL: ${test_name} - value is empty"
  fi
}

assert_valid_json() {
  local json="$1"
  local test_name="$2"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  if echo "$json" | jq empty 2>/dev/null; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "✅ PASS: ${test_name}"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "❌ FAIL: ${test_name} - invalid JSON"
  fi
}

# ============================================================================
# Tests - GDPR Functions
# ============================================================================

test_pseudonymize_ip() {
  echo ""
  echo "Testing IP pseudonymization..."
  
  local result
  
  result=$(pseudonymize_ip "192.168.1.42")
  assert_equals "192.168.xxx.xxx" "$result" "IPv4 pseudonymization"
  
  result=$(pseudonymize_ip "10.0.50.100")
  assert_equals "10.0.xxx.xxx" "$result" "IPv4 pseudonymization (10.x)"
  
  result=$(pseudonymize_ip "")
  assert_equals "unknown" "$result" "Empty IP"
}

test_pseudonymize_username() {
  echo ""
  echo "Testing username pseudonymization..."
  
  local result
  
  result=$(pseudonymize_username "admin")
  assert_not_empty "$result" "Username pseudonymization"
  
  result=$(pseudonymize_username "")
  assert_equals "unknown" "$result" "Empty username"
}

# ============================================================================
# Tests - Status Functions
# ============================================================================

test_determine_status() {
  echo ""
  echo "Testing status determination..."
  
  local result
  
  result=$(determine_status 50 70 85 "gt")
  assert_equals "healthy" "$result" "Status: value below warning"
  
  result=$(determine_status 75 70 85 "gt")
  assert_equals "warning" "$result" "Status: value between warning and critical"
  
  result=$(determine_status 90 70 85 "gt")
  assert_equals "critical" "$result" "Status: value above critical"
}

test_get_worst_status() {
  echo ""
  echo "Testing worst status calculation..."
  
  local result
  
  result=$(get_worst_status "healthy" "healthy" "healthy")
  assert_equals "healthy" "$result" "All healthy"
  
  result=$(get_worst_status "healthy" "warning" "healthy")
  assert_equals "warning" "$result" "One warning"
  
  result=$(get_worst_status "healthy" "warning" "critical")
  assert_equals "critical" "$result" "One critical"
  
  result=$(get_worst_status "critical" "warning" "healthy")
  assert_equals "critical" "$result" "Critical dominates"
}

# ============================================================================
# Tests - JSON Report Building
# ============================================================================

test_init_report() {
  echo ""
  echo "Testing report initialization..."
  
  local report
  report=$(init_report "test")
  
  assert_valid_json "$report" "Init report produces valid JSON"
  
  local module
  module=$(echo "$report" | jq -r '.metadata.module')
  assert_equals "test" "$module" "Report module name"
  
  local version
  version=$(echo "$report" | jq -r '.metadata.version')
  assert_not_empty "$version" "Report version"
}

test_add_check() {
  echo ""
  echo "Testing add check to report..."
  
  local report
  report=$(init_report "test")
  
  report=$(add_check "$report" "test.check1" "Test Check" "healthy" "All good" "100")
  
  assert_valid_json "$report" "Report with check is valid JSON"
  
  local check_count
  check_count=$(echo "$report" | jq '[.checks[]] | length')
  assert_equals "1" "$check_count" "Check added to report"
  
  local check_id
  check_id=$(echo "$report" | jq -r '.checks[0].id')
  assert_equals "test.check1" "$check_id" "Check ID matches"
}

test_add_alert() {
  echo ""
  echo "Testing add alert to report..."
  
  local report
  report=$(init_report "test")
  
  report=$(add_alert "$report" "warning" "test.source" "Test alert message")
  
  assert_valid_json "$report" "Report with alert is valid JSON"
  
  local alert_count
  alert_count=$(echo "$report" | jq '[.alerts[]] | length')
  assert_equals "1" "$alert_count" "Alert added to report"
  
  local alert_severity
  alert_severity=$(echo "$report" | jq -r '.alerts[0].severity')
  assert_equals "warning" "$alert_severity" "Alert severity matches"
}

test_update_status() {
  echo ""
  echo "Testing update report status..."
  
  local report
  report=$(init_report "test")
  
  report=$(update_status "$report" "critical")
  
  local status
  status=$(echo "$report" | jq -r '.status')
  assert_equals "critical" "$status" "Status updated"
}

# ============================================================================
# Run All Tests
# ============================================================================

main() {
  echo "========================================="
  echo "LexOrbital Surveillance - Common Library Tests"
  echo "========================================="
  
  # GDPR tests
  test_pseudonymize_ip
  test_pseudonymize_username
  
  # Status tests
  test_determine_status
  test_get_worst_status
  
  # JSON tests
  test_init_report
  test_add_check
  test_add_alert
  test_update_status
  
  # Summary
  echo ""
  echo "========================================="
  echo "Test Results"
  echo "========================================="
  echo "Total:  ${TESTS_RUN}"
  echo "Passed: ${TESTS_PASSED}"
  echo "Failed: ${TESTS_FAILED}"
  echo "========================================="
  
  if [[ ${TESTS_FAILED} -eq 0 ]]; then
    echo "✅ All tests passed!"
    exit 0
  else
    echo "❌ Some tests failed"
    exit 1
  fi
}

main "$@"

