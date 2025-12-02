#!/usr/bin/env bash
# ============================================================================
# Integration Tests for LexOrbital Surveillance System
# ============================================================================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Test configuration
TEST_OUTPUT_DIR="/tmp/lexorbital-surveillance-test"
MODULES_DIR="${SCRIPT_DIR}/../modules"
ORCHESTRATOR="${SCRIPT_DIR}/../orchestrator/surveillance-orchestrator.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================================
# Setup & Teardown
# ============================================================================

setup() {
  echo "Setting up test environment..."
  
  # Create test output directory
  mkdir -p "${TEST_OUTPUT_DIR}/reports"
  mkdir -p "${TEST_OUTPUT_DIR}/config"
  mkdir -p "${TEST_OUTPUT_DIR}/checksums"
  
  # Set test environment variables
  export SURVEILLANCE_DIR="${TEST_OUTPUT_DIR}"
  export SURVEILLANCE_REPORTS_DIR="${TEST_OUTPUT_DIR}/reports"
  export SURVEILLANCE_CONFIG_DIR="${TEST_OUTPUT_DIR}/config"
  export SURVEILLANCE_LOG_FILE="${TEST_OUTPUT_DIR}/surveillance.log"
  export SURVEILLANCE_DEBUG="false"
  
  # Make scripts executable
  chmod +x "${MODULES_DIR}"/*.sh 2>/dev/null || true
  chmod +x "${ORCHESTRATOR}" 2>/dev/null || true
  
  echo "✅ Test environment ready"
}

teardown() {
  echo "Cleaning up test environment..."
  # Uncomment to clean up after tests
  # rm -rf "${TEST_OUTPUT_DIR}"
  echo "✅ Cleanup complete"
}

# ============================================================================
# Test Helpers
# ============================================================================

test_result() {
  local passed="$1"
  local test_name="$2"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  if [[ "$passed" == "true" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✅ PASS${NC}: ${test_name}"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}❌ FAIL${NC}: ${test_name}"
    return 1
  fi
}

# ============================================================================
# Module Tests
# ============================================================================

test_module_resources() {
  echo ""
  echo "Testing resources module..."
  
  local script="${MODULES_DIR}/surveillance-resources.sh"
  
  # Test script exists
  if [[ ! -f "$script" ]]; then
    test_result "false" "Resources module script exists"
    return
  fi
  test_result "true" "Resources module script exists"
  
  # Test execution
  if bash "$script" > /dev/null 2>&1; then
    test_result "true" "Resources module executes"
  else
    test_result "false" "Resources module executes"
    return
  fi
  
  # Test report generation
  local report_file="${SURVEILLANCE_REPORTS_DIR}/resources.json"
  if [[ -f "$report_file" ]]; then
    test_result "true" "Resources module generates report"
  else
    test_result "false" "Resources module generates report"
    return
  fi
  
  # Test JSON validity
  if jq empty "$report_file" 2>/dev/null; then
    test_result "true" "Resources report is valid JSON"
  else
    test_result "false" "Resources report is valid JSON"
    return
  fi
  
  # Test report structure
  local has_metadata has_status has_checks
  has_metadata=$(jq -e '.metadata' "$report_file" >/dev/null 2>&1 && echo "true" || echo "false")
  has_status=$(jq -e '.status' "$report_file" >/dev/null 2>&1 && echo "true" || echo "false")
  has_checks=$(jq -e '.checks' "$report_file" >/dev/null 2>&1 && echo "true" || echo "false")
  
  [[ "$has_metadata" == "true" && "$has_status" == "true" && "$has_checks" == "true" ]] && \
    test_result "true" "Resources report has correct structure" || \
    test_result "false" "Resources report has correct structure"
}

test_module_security() {
  echo ""
  echo "Testing security module..."
  
  local script="${MODULES_DIR}/surveillance-security.sh"
  
  if [[ ! -f "$script" ]]; then
    test_result "false" "Security module script exists"
    return
  fi
  test_result "true" "Security module script exists"
  
  if bash "$script" > /dev/null 2>&1; then
    test_result "true" "Security module executes"
  else
    test_result "false" "Security module executes"
  fi
  
  local report_file="${SURVEILLANCE_REPORTS_DIR}/security.json"
  if [[ -f "$report_file" ]] && jq empty "$report_file" 2>/dev/null; then
    test_result "true" "Security module generates valid report"
  else
    test_result "false" "Security module generates valid report"
  fi
}

test_module_services() {
  echo ""
  echo "Testing services module..."
  
  local script="${MODULES_DIR}/surveillance-services.sh"
  
  if [[ ! -f "$script" ]]; then
    test_result "false" "Services module script exists"
    return
  fi
  test_result "true" "Services module script exists"
  
  if bash "$script" > /dev/null 2>&1; then
    test_result "true" "Services module executes"
  else
    test_result "false" "Services module executes"
  fi
  
  local report_file="${SURVEILLANCE_REPORTS_DIR}/services.json"
  if [[ -f "$report_file" ]] && jq empty "$report_file" 2>/dev/null; then
    test_result "true" "Services module generates valid report"
  else
    test_result "false" "Services module generates valid report"
  fi
}

test_module_network() {
  echo ""
  echo "Testing network module..."
  
  local script="${MODULES_DIR}/surveillance-network.sh"
  
  if [[ ! -f "$script" ]]; then
    test_result "false" "Network module script exists"
    return
  fi
  test_result "true" "Network module script exists"
  
  if bash "$script" > /dev/null 2>&1; then
    test_result "true" "Network module executes"
  else
    test_result "false" "Network module executes"
  fi
  
  local report_file="${SURVEILLANCE_REPORTS_DIR}/network.json"
  if [[ -f "$report_file" ]] && jq empty "$report_file" 2>/dev/null; then
    test_result "true" "Network module generates valid report"
  else
    test_result "false" "Network module generates valid report"
  fi
}

test_module_integrity() {
  echo ""
  echo "Testing integrity module..."
  
  local script="${MODULES_DIR}/surveillance-integrity.sh"
  
  if [[ ! -f "$script" ]]; then
    test_result "false" "Integrity module script exists"
    return
  fi
  test_result "true" "Integrity module script exists"
  
  # Initialize integrity database first
  bash "$script" --init > /dev/null 2>&1 || true
  
  if bash "$script" > /dev/null 2>&1; then
    test_result "true" "Integrity module executes"
  else
    test_result "false" "Integrity module executes"
  fi
  
  local report_file="${SURVEILLANCE_REPORTS_DIR}/integrity.json"
  if [[ -f "$report_file" ]] && jq empty "$report_file" 2>/dev/null; then
    test_result "true" "Integrity module generates valid report"
  else
    test_result "false" "Integrity module generates valid report"
  fi
}

# ============================================================================
# Orchestrator Tests
# ============================================================================

test_orchestrator() {
  echo ""
  echo "Testing orchestrator..."
  
  if [[ ! -f "$ORCHESTRATOR" ]]; then
    test_result "false" "Orchestrator script exists"
    return
  fi
  test_result "true" "Orchestrator script exists"
  
  # Test execution with specific modules
  if bash "$ORCHESTRATOR" --modules resources > /dev/null 2>&1; then
    test_result "true" "Orchestrator executes"
  else
    test_result "false" "Orchestrator executes"
    return
  fi
  
  # Test global report generation
  local global_report="${SURVEILLANCE_REPORTS_DIR}/global.json"
  if [[ -f "$global_report" ]]; then
    test_result "true" "Orchestrator generates global report"
  else
    test_result "false" "Orchestrator generates global report"
    return
  fi
  
  # Test global report JSON validity
  if jq empty "$global_report" 2>/dev/null; then
    test_result "true" "Global report is valid JSON"
  else
    test_result "false" "Global report is valid JSON"
    return
  fi
  
  # Test global report structure
  local has_global_status has_modules has_summary
  has_global_status=$(jq -e '.globalStatus' "$global_report" >/dev/null 2>&1 && echo "true" || echo "false")
  has_modules=$(jq -e '.modules' "$global_report" >/dev/null 2>&1 && echo "true" || echo "false")
  has_summary=$(jq -e '.summary' "$global_report" >/dev/null 2>&1 && echo "true" || echo "false")
  
  [[ "$has_global_status" == "true" && "$has_modules" == "true" && "$has_summary" == "true" ]] && \
    test_result "true" "Global report has correct structure" || \
    test_result "false" "Global report has correct structure"
}

# ============================================================================
# Main Test Runner
# ============================================================================

main() {
  echo "========================================="
  echo "LexOrbital Surveillance - Integration Tests"
  echo "========================================="
  
  # Setup
  setup
  
  # Run module tests
  test_module_resources
  test_module_security
  test_module_services
  test_module_network
  test_module_integrity
  
  # Run orchestrator tests
  test_orchestrator
  
  # Teardown
  teardown
  
  # Summary
  echo ""
  echo "========================================="
  echo "Test Results"
  echo "========================================="
  echo "Total:  ${TESTS_RUN}"
  echo -e "Passed: ${GREEN}${TESTS_PASSED}${NC}"
  echo -e "Failed: ${RED}${TESTS_FAILED}${NC}"
  echo "========================================="
  
  if [[ ${TESTS_FAILED} -eq 0 ]]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
  else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
  fi
}

main "$@"

