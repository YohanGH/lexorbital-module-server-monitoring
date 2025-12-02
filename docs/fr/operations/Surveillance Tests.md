# LexOrbital Surveillance Tests

Test suite for the surveillance system.

## 📁 Test Files

- `test-surveillance-common.sh` - Unit tests for common library functions
- `test-integration.sh` - Integration tests for all modules and orchestrator

## 🚀 Running Tests

### Prerequisites

```bash
# Ensure jq is installed
sudo apt-get install -y jq

# Make test scripts executable
chmod +x monitoring/tests/*.sh
```

### Run Unit Tests

```bash
cd monitoring/tests
./test-surveillance-common.sh
```

### Run Integration Tests

```bash
cd monitoring/tests
./test-integration.sh
```

### Run All Tests

```bash
cd monitoring/tests
./test-surveillance-common.sh && ./test-integration.sh
```

## 📊 Test Coverage

### Unit Tests

- ✅ IP pseudonymization (GDPR)
- ✅ Username pseudonymization
- ✅ Status determination (healthy/warning/critical)
- ✅ Worst status calculation
- ✅ JSON report initialization
- ✅ Adding checks to reports
- ✅ Adding alerts to reports
- ✅ Updating report status

### Integration Tests

- ✅ Resources module execution
- ✅ Security module execution
- ✅ Services module execution
- ✅ Network module execution
- ✅ Integrity module execution
- ✅ Orchestrator execution
- ✅ Report generation and validation
- ✅ JSON structure validation

## 🧪 Test Environment

Tests run in an isolated environment:

- Test output directory: `/tmp/lexorbital-surveillance-test`
- No impact on production surveillance data
- Automatic cleanup after tests (optional)

## 📝 Writing New Tests

### Unit Test Template

```bash
test_my_function() {
  echo ""
  echo "Testing my function..."
  
  local result
  result=$(my_function "input")
  
  assert_equals "expected" "$result" "Test description"
}
```

### Integration Test Template

```bash
test_my_module() {
  echo ""
  echo "Testing my module..."
  
  local script="${MODULES_DIR}/surveillance-mymodule.sh"
  
  if bash "$script" > /dev/null 2>&1; then
    test_result "true" "Module executes"
  else
    test_result "false" "Module executes"
  fi
}
```

## 🐛 Debugging Failed Tests

```bash
# Enable debug mode
export SURVEILLANCE_DEBUG=true

# Run tests with verbose output
./test-integration.sh

# Check test output directory
ls -la /tmp/lexorbital-surveillance-test/
cat /tmp/lexorbital-surveillance-test/surveillance.log
```

## 📈 CI/CD Integration

### GitHub Actions Example

```yaml
name: Surveillance Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Install dependencies
        run: sudo apt-get install -y jq
      
      - name: Run unit tests
        run: ./monitoring/tests/test-surveillance-common.sh
      
      - name: Run integration tests
        run: ./monitoring/tests/test-integration.sh
```

## 🔧 Troubleshooting

### jq not found

```bash
sudo apt-get install -y jq
```

### Permission denied

```bash
chmod +x monitoring/tests/*.sh
chmod +x monitoring/modules/*.sh
chmod +x monitoring/orchestrator/*.sh
chmod +x monitoring/lib/*.sh
```

### Test output directory not writable

```bash
sudo mkdir -p /tmp/lexorbital-surveillance-test
sudo chmod 777 /tmp/lexorbital-surveillance-test
```

---

**Version**: 1.0.0  
**Last updated**: 2025-12-02

