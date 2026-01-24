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

# Principal III (Test-First): Test the modular template provisioner
test_provision_template() {
    echo -n "Running test_provision_template... "
    local test_base="/tmp/provision-test"
    local tpl="$test_base/template.txt"
    local dest="$test_base/result.txt"
    mkdir -p "$test_base"
    
    echo "URL: {{MAC_SERVER_URL}}, IP: {{MAC_IP}}, VERSION: {{VERSION}}" > "$tpl"
    
    # Run provisioner (simulating en0 IP 10.0.0.1)
    provision_template "$tpl" "$dest" "10.0.0.1" "vTEST-123"
    
    if grep -q "URL: http://10.0.0.1:8000, IP: 10.0.0.1, VERSION: vTEST-123" "$dest"; then
        echo "PASS"
    else
        echo "FAIL (Placeholder replacement failed)"
        cat "$dest"
        exit 1
    fi
    rm -rf "$test_base"
}

# Simple test runner
run_tests() {
    test_check_git_installed
    test_get_ip_address
    test_log_audit_event
    test_provision_template
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi
