#!/usr/bin/env bash

# setup the test script

setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    load 'test_helper/bats-file/load'
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    PATH="$DIR/..:$PATH"
}

@test "test that the script is executable" {
    assert_file_executable "$DIR/../createCa.sh"
}
@test "Test Creating the CA - should return cacerts/testca.crt" {
    run test/testCreateCa.exp

    assert_output --partial 'cacerts/testca.crt'
}

@test "Test createCert should confirm cert was created" {
    run test/testNewCert.exp
    assert_output --partial 'Creating PFX for Windows servers'
}

@test "Test revokeCert should say Data Base Updated" {
    run test/testRevokeCert.exp
    assert_output --partial 'Data Base Updated'
}

#@test "createCA and createCert should return PFX Confirming the cert was created" {
#    run test/testCreateCa.exp
#    assert_output --partial 'cacerts/testca.crt'
#    run test/testNewCert.exp
#    assert_output --partial 'Creating PFX for Windows servers'
#}


teardown_file() {
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    "$DIR"/../fixup.sh
}
#teardown() {
#    "$DIR"/../fixup.sh
##    rm -f /tmp/output
#}