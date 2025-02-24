load ../bats_setup

@test "BBS W3C" {
    ${ZENROOM_EXECUTABLE} $T/check_w3c-vc-di-bbs.lua
}
