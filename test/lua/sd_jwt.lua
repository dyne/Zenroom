local SD_JWT = require'crypto_sd_jwt'

local sdr = {
    fields = {
        O.from_string("given_name"),O.from_string("family_name"),O.from_string("email"),O.from_string("phone_number"),
        O.from_string("phone_number_verified"),O.from_string("address"),O.from_string("birthdate")},
    object = {
        given_name = O.from_string("John"),
        family_name = O.from_string("Doe"),
        email = O.from_string("johndoe@example.com"),
        phone_number = O.from_string("+1-202-555-0101"),
        phone_number_verified = true,
        address = {
            street_address = O.from_string("123 Main St"),
            locality = O.from_string("Anytown"),
            region = O.from_string("Anystate"),
            country = O.from_string("US")
        },
        birthdate = O.from_string("1940-01-01"),
        updated_at = 1570000000,
        nationalities = {
            O.from_string("US"),
            O.from_string("DE")
        }
    }
}

--Test vectors from Section 6.1 of https://datatracker.ietf.org/doc/draft-ietf-oauth-selective-disclosure-jwt/
local _sd = {
    "CrQe7S5kqBAHt-nMYXgc6bdt2SH5aTY1sU_M-PgkjPI",
    "JzYjH4svliH0R3PyEMfeZu6Jt69u5qehZo7F7EPYlSE",
    "PorFbpKuVu6xymJagvkFsFXAbRoc2JGlAUA2BA4o7cI",
    "TGf4oLbgwd5JQaHyKVQZU9UdGE0w5rtDsrZzfUaomLo",
    "XQ_3kPKt1XyX7KANkqVR6yZ2Va5NrPIvPYbyMvRKBMM",
    "XzFrzwscM6Gn6CJDc6vVK8BkMnfG8vOSKfpPIZdAfdE",
    "gbOsI4Edq2x2Kw-w5wPEzakob9hV1cRD0ATN3oQL9JM",
    "jsu9yVulwQQlhFlM_3JlzMaSFzglhQG0DpfayQwLUK4"
}
local contents = {
    {"2GLC42sKQveCfGfryNRN9w", "given_name", "John"},
    {"eluV5Og3gSNII8EYnsxA_A", "family_name", "Doe"},
    {"6Ij7tM-a5iVPGboS5tmvVA", "email", "johndoe@example.com"},
    {"eI8ZWm9QnKPpNPeNenHdhQ", "phone_number", "+1-202-555-0101"},
    {"Qg_O64zqAxe412a108iroA", "phone_number_verified", true},
    --{"AJx-095VPrpTtN4QMOqROA", "address", {street_address = "123 Main St", locality = "Anytown", region = "Anystate", country = "US"}},
    {"Pc33JM2LchcU_lHggv_ufQ", "birthdate", "1940-01-01"},
    {"G02NSrQfjFXQ7Io09syajA", "updated_at", 1570000000}
}

local hashed = {
    "jsu9yVulwQQlhFlM_3JlzMaSFzglhQG0DpfayQwLUK4",
    "TGf4oLbgwd5JQaHyKVQZU9UdGE0w5rtDsrZzfUaomLo",
    "JzYjH4svliH0R3PyEMfeZu6Jt69u5qehZo7F7EPYlSE",
    "PorFbpKuVu6xymJagvkFsFXAbRoc2JGlAUA2BA4o7cI",
    "XQ_3kPKt1XyX7KANkqVR6yZ2Va5NrPIvPYbyMvRKBMM",
    --"XzFrzwscM6Gn6CJDc6vVK8BkMnfG8vOSKfpPIZdAfdE",
    "gbOsI4Edq2x2Kw-w5wPEzakob9hV1cRD0ATN3oQL9JM",
    "CrQe7S5kqBAHt-nMYXgc6bdt2SH5aTY1sU_M-PgkjPI"
}

local disclosures = {
    "WyIyR0xDNDJzS1F2ZUNmR2ZyeU5STjl3IiwgImdpdmVuX25hbWUiLCAiSm9obiJd",
    "WyJlbHVWNU9nM2dTTklJOEVZbnN4QV9BIiwgImZhbWlseV9uYW1lIiwgIkRvZSJd",
    "WyI2SWo3dE0tYTVpVlBHYm9TNXRtdlZBIiwgImVtYWlsIiwgImpvaG5kb2VAZXhhbXBsZS5jb20iXQ",
    "WyJlSThaV205UW5LUHBOUGVOZW5IZGhRIiwgInBob25lX251bWJlciIsICIrMS0yMDItNTU1LTAxMDEiXQ",
    "WyJRZ19PNjR6cUF4ZTQxMmExMDhpcm9BIiwgInBob25lX251bWJlcl92ZXJpZmllZCIsIHRydWVd",
    --"WyJBSngtMDk1VlBycFR0TjRRTU9xUk9BIiwgImFkZHJlc3MiLCB7InN0cmVldF9hZGRyZXNzIjogIjEyMyBNYWluIFN0IiwgImxvY2FsaXR5IjogIkFueXRvd24iLCAicmVnaW9uIjogIkFueXN0YXRlIiwgImNvdW50cnkiOiAiVVMifV0",
    "WyJQYzMzSk0yTGNoY1VfbEhnZ3ZfdWZRIiwgImJpcnRoZGF0ZSIsICIxOTQwLTAxLTAxIl0",
    "WyJHMDJOU3JRZmpGWFE3SW8wOXN5YWpBIiwgInVwZGF0ZWRfYXQiLCAxNTcwMDAwMDAwXQ"
}

for i = 1, #contents do
    print("Test case "..i)
    local _, hashd, dis = SD_JWT.create_disclosure(contents[i])

    zencode_assert(dis == disclosures[i], "Wrong disclosure")
    zencode_assert(hashd == O.from_string(hashed[i]), "Wrong hash")
end
