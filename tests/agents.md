# AI Agent Guidelines

## Purpose
This directory contains integrated testing framework for bash.d ecosystem including unit tests, integration tests, and end-to-end testing.

## File Placement Rules
- `unit.sh`: Unit tests for individual functions and modules
- `integration.sh`: Integration tests for component interactions
- `e2e.sh`: End-to-end tests for complete workflows
- `test_helpers.sh`: Common testing utilities and fixtures
- `mocks/`: Mock data and API responses for testing
- `coverage/`: Test coverage reports and metrics
- `performance/`: Load testing and performance benchmarks

## File Naming Conventions
- Test files: `test_module_functionality.sh`
- Mock files: `mock_service_response.json`
- Coverage files: `coverage_module_YYYY-MM-DD.json`
- Performance files: `perf_test_name_YYYY-MM-DD.log`
- Helper files: `helper_test_utility.sh`

## Automation Instructions
- AI agents should run tests before any deployment
- Implement proper test isolation and cleanup
- Use mocking for external service dependencies
- Generate coverage reports for all test runs
- Implement performance regression testing
- Use test-driven development for new features

## Integration Points
- Tests all components from `../src/`
- Validates plugin functionality from `../plugins/`
- Tests infrastructure deployment from `../infrastructure/`
- Validates platform functionality from `../platform/`
- Uses test data from `../data/test/`
- Reports results to central logging system

## Context
This directory ensures quality and reliability of bash.d ecosystem through:
- Automated testing of all functionality
- Continuous integration and deployment
- Performance monitoring and regression testing
- Code coverage analysis and improvement
- Mock-based testing for external dependencies
- Comprehensive test reporting and analytics

## Testing Framework Structure
```bash
# Standard test structure
test_setup() {
    # Setup test environment
}

test_teardown() {
    # Cleanup test environment
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    
    if [[ "$expected" == "$actual" ]]; then
        echo "✅ PASS: $message"
    else
        echo "❌ FAIL: $message (expected: $expected, got: $actual)"
        return 1
    fi
}
```

## Test Categories
- **Unit Tests**: Individual function testing
- **Integration Tests**: Component interaction testing
- **End-to-End Tests**: Complete workflow testing
- **Performance Tests**: Load and stress testing
- **Security Tests**: Vulnerability and penetration testing
- **Compatibility Tests**: Cross-platform testing

## Quality Standards
- Minimum 80% code coverage
- All tests must pass before deployment
- Performance regression <5% degradation
- Security tests must pass for production
- Documentation must be updated with features
- All external dependencies must be mocked

## Test Data Management
- Use realistic but anonymized test data
- Implement proper data cleanup between tests
- Use consistent test datasets for reproducibility
- Validate test data integrity before use
- Implement test data versioning
- Use separate test databases and storage

## Continuous Integration
- Run tests on every commit
- Parallel test execution for speed
- Automated test reporting
- Integration with GitHub/GitLab CI/CD
- Automated deployment on test success
- Rollback on test failure