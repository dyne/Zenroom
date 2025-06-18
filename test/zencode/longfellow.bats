load ../bats_setup
load ../bats_zencode
SUBDOC=longfellow

@test "Generate longfellow circuit" {
    cat << EOF | $ZENROOM_EXECUTABLE -z | tee "$BATS_FILE_TMPDIR/longfellow_circuit_1.json"
Scenario longfellow
Given nothing
When I create the circuit id '1'
Then print the 'circuit'
EOF
}

@test "Use circuit and sprind-funke example to generate a zk-proof" {
    cat <<EOF > $BATS_FILE_TMPDIR/age_over_18.json
{
 "now": "2024-10-01T09:00:00Z",
 "sd": [{ "id": "family_name", "value": "Mustermann" }],
 "transcript": "83f6f6847142726f7773657248616e646f76657276315820f93ebac4ce4d9901b9aea472145ae5421f8fbecbe5f0389683f59f08fcf90e455833a363636174016474797065016764657461696c73a1676261736555726c75687474703a2f2f6c6f63616c686f73743a3830383058203c79914b7f81a1c2558fc81619dd4a074d32143e6cf6895fe47da156d1c5b0ae",
 "public_key": "dc1c1f55cff4cd5c76cf4169278f7217667f86ee81d8669b63f2e19bc12a0c9f12355dd0385fed3bc33bedc9781b9aad47b33e4c24704b8d14288b1b3cb45c28",
 "document": "o2d2ZXJzaW9uYzEuMGlkb2N1bWVudHOBo2dkb2NUeXBldW9yZy5pc28uMTgwMTMuNS4xLm1ETGxpc3N1ZXJTaWduZWSiam5hbWVTcGFjZXOhcW9yZy5pc28uMTgwMTMuNS4xhdgYWFqkaGRpZ2VzdElEGBpmcmFuZG9tUHLHryZJ0Fo4sC5+HMf50EZxZWxlbWVudElkZW50aWZpZXJrZmFtaWx5X25hbWVsZWxlbWVudFZhbHVlak11c3Rlcm1hbm7YGFhbpGhkaWdlc3RJRApmcmFuZG9tUPyKj1uvtAyzIXdtv1++GIFxZWxlbWVudElkZW50aWZpZXJqYmlydGhfZGF0ZWxlbGVtZW50VmFsdWXZA+xqMTk3MS0wOS0wMdgYWFukaGRpZ2VzdElEFGZyYW5kb21QWc3dkddT7Zj/VV0vlydFO3FlbGVtZW50SWRlbnRpZmllcmppc3N1ZV9kYXRlbGVsZW1lbnRWYWx1ZdkD7GoyMDI0LTAzLTE12BhYS6RoZGlnZXN0SUQPZnJhbmRvbVDM3FmMqa/ulf1XaD6xmv8zcWVsZW1lbnRJZGVudGlmaWVyZmhlaWdodGxlbGVtZW50VmFsdWUYr9gYWE+kaGRpZ2VzdElEFWZyYW5kb21QrFD2UbwE8AHQIWOEfJ8cyXFlbGVtZW50SWRlbnRpZmllcmthZ2Vfb3Zlcl8xOGxlbGVtZW50VmFsdWX1amlzc3VlckF1dGiEQ6EBJqEYIVkCgzCCAn8wggIloAMCAQICEDUAupvv2Ry52nkF/+8YvoowCgYIKoZIzj0EAwIwOTELMAkGA1UEBhMCVVQxKjAoBgNVBAMMIU9XRiBJZGVudGl0eSBDcmVkZW50aWFsIFRFU1QgSUFDQTAeFw0yNDA5MDIxNzIxMTNaFw0yNTA5MDIxNzIxMTNaMDcxKDAmBgNVBAMMH09XRiBJZGVudGl0eSBDcmVkZW50aWFsIFRFU1QgRFMxCzAJBgNVBAYTAlVUMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE3BwfVc/0zVx2z0FpJ49yF2Z/hu6B2GabY/Lhm8EqDJ8SNV3QOF/tO8M77cl4G5qtR7M+TCRwS40UKIsbPLRcKKOCAQ8wggELMB0GA1UdDgQWBBQTCc6GC53/vIWZKDod2cHzVWpj8TAfBgNVHSMEGDAW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"
}
EOF

    cat <<EOF | $ZENROOM_EXECUTABLE -z -a longfellow_circuit_1.json -k age_over_18.json > $BATS_FILE_TMPDIR/proof.json
Scenario longfellow
Given I have a 'circuit'
and 'attributes' named 'sd'
and a 'string' named 'now'
and a 'hex' named 'transcript'
and a 'hex' named 'public key'
and a 'base64' named 'document'
When I create the proof of attributes 'sd' in mdoc 'document'
and I create the new dictionary named 'parameters'
and I move 'transcript' as 'hex' in 'parameters'
and I move 'public key' as 'hex' in 'parameters'
and I move 'now' as 'string' in 'parameters'
and I move 'sd' as 'string' in 'parameters'
Then print 'proof'
Then print 'parameters'
EOF
    # assert_line --partial 'ALL OK'
    # save_output 'import_circuit.json'
    # assert_output ''
}

# TEMPORARY WIP
# copy and execute the command below to generate circuits
# cat <<EOF | ./zenroom -z > longfellow_circuit1.json
# Scenario longfellow
# Given nothing
# When I create the longfellow circuit id '1'
# and schema
# Then print the 'longfellow circuit' as 'longfellow circuit'
# EOF

@test "Verify the zk-proof of the previous example" {
    # remove the document from verification parameters
    cat <<EOF | $ZENROOM_EXECUTABLE -z -a longfellow_circuit_1.json -k $BATS_FILE_TMPDIR/proof.json >&3
Scenario longfellow
Given I have a 'proof'
and I have a 'circuit'
and I have a 'hex' named 'transcript' in 'parameters'
and I have a 'hex' named 'public key' in 'parameters'
and I have a 'string' named 'now' in 'parameters'
and I have 'attributes' named 'sd' in 'parameters'
When I verify the proof of attributes 'sd' in proof 'proof'
Then print string 'ALL OK'
EOF


}
