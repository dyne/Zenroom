load ../bats_setup

@test "Statement registration conflicts stay centralized" {
    cd "$R"
    run $ZENROOM_EXECUTABLE test/lua/statement_registration.lua
    assert_success
    assert_line --partial 'statement registration regressions OK'
}
