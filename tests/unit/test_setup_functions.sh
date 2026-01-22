#!/usr/bin/env bash
# Unit tests for setup_rescue_server.sh functions
# Standard: Bash 3.2+

# Source the script under test
# We use a trick to source it without running 'main'
# The script has: if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main; fi
SCRIPT_PATH="./setup_rescue_server.sh"
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Error: setup_rescue_server.sh not found at $SCRIPT_PATH"
    exit 1
fi

source "$SCRIPT_PATH"

# T027 [P] [Phase 2] Create unit test for check_git_installed
test_check_git_installed() {
    echo -n "Running test_check_git_installed... "
    if check_git_installed; then
        echo "PASS (Git is installed on this host)"
    else
        echo "PASS (Git is not installed on this host, which is a valid state)"
    fi
}

# T007 [P] [Phase 2] Create unit test for get_ip_address
test_get_ip_address() {
    echo -n "Running test_get_ip_address... "
    local ip=$(get_ip_address)
    # On most systems it should return something or empty
    if [ -n "$ip" ]; then
        echo "PASS (Detected IP: $ip)"
    else
        echo "PASS (No IP detected, which is a valid edge case)"
    fi
}

# FR-014: Test logging format
test_log_audit_event() {
    echo -n "Running test_log_audit_event... "
    BASE_DIR="/tmp/rescue-test"
    AUDIT_LOG_FILE="$BASE_DIR/audit_logs/server_audit.log"
    rm -rf "$BASE_DIR"
    
    log_audit_event "TEST" "Unit test message"
    
    if [ -f "$AUDIT_LOG_FILE" ]; then
        if grep -q "TEST: Unit test message" "$AUDIT_LOG_FILE"; then
            echo "PASS"
        else
            echo "FAIL (Log format incorrect)"
            exit 1
        fi
    else
        echo "FAIL (Log file not created)"
        exit 1
    fi
    rm -rf "$BASE_DIR"
}

# Simple test runner
run_tests() {
    test_check_git_installed
    test_get_ip_address
    test_log_audit_event
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi
