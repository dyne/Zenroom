load ../bats_setup

@test "Scenario-private globals stay local" {
    cd "$R"
    run $ZENROOM_EXECUTABLE test/lua/scenario_globals.lua
    assert_success
    assert_line --partial 'scenario globals regressions OK'
}
