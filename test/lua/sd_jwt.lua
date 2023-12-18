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

print("Test Disclosures 1")
for i = 1, #contents do
    print("Test case "..i)
    local _, hashd, dis = SD_JWT.create_disclosure(contents[i])

    zencode_assert(dis == disclosures[i], "Wrong disclosure")
    zencode_assert(hashd == O.from_string(hashed[i]), "Wrong hash")
end

-- Test vectors from section A.3 of https://www.rfc-editor.org/rfc/rfc7515.html

local test_sdr = {
    object = {
        iss = O.from_string("https://pid-provider.memberstate.example.eu"),
        iat = 1541493724,
        type = O.from_string("PersonIdentificationData"),
        first_name = O.from_string("Erika"),
        family_name = O.from_string("Mustermann"),
        nationalities = {O.from_string("DE")},
        birth_family_name = O.from_string("Schmidt"),
        birthdate = O.from_string("1973-01-01"),
        address = {
            postal_code = O.from_string("12345"),
            locality = O.from_string("Irgendwo"),
            street_address = O.from_string("Sonnenstrasse 23"),
            country_code = O.from_string("DE")
        },
        is_over_18 = true,
        is_over_21 = true,
        is_over_65 = false,
        exp = 1883000000,
        cnf = {
            jwk = {
                kty = O.from_string("EC"),
                crv = O.from_string("P-256"),
                x = "TCAER19Zvu3OHF4j4W4vfSVoHIP1ILilDls7vCeGemc",
                y = "ZxjiWWbZMQGHVWKVQ4hbSIirsVfuecCE6t4jT9F2HZQ"
            }
        }
    },
    fields = {
        O.from_string("first_name"),
        O.from_string("family_name"),
        O.from_string("nationalities"),
        O.from_string("birth_family_name"),
        O.from_string("birthdate"),
        O.from_string("address"),
        O.from_string("is_over_18"),
        O.from_string("is_over_21"),
        O.from_string("is_over_65")
    }
}

local sd_jwt = "eyJhbGciOiAiRVMyNTYifQ.eyJfc2QiOiBbIjBuOXl6RlNXdktfQlVIaWFNaG0xMmdockN0VmFockdKNl8ta1pQLXlTcTQiLCAiQ2gtREJjTDNrYjRWYkhJd3Rrbm5aZE5VSHRoRXE5TVpqb0ZkZzZpZGlobyIsICJEVzdnRlZaU3V5cjQyWVNZeDhwOHJWS0VrdEp6SjN1RkltZW5tSkJJbWRzIiwgIkkwMGZjRlVvRFhDdWNwNXl5MnVqcVBzc0RWR2FXTmlVbGlOel9hd0QwZ2MiLCAiWDlNYVBhRldtUVlwZkhFZHl0UmRhY2xuWW9FcnU4RXp0QkVVUXVXT2U0NCIsICJkOHFrZlBkb2UyUFlFOTNkNU1fZ0JMMWdabHBGUktDYzBkMWxhb2RfX3MwIiwgImxJM0wwaHNlQ1JXbVVQZzgyVkNVTl9hMTdzTUxfNjRRZ0E0SkZUWURGREUiLCAicHVNcEdMb0FHUmJjc0FnNTBVWjBoaFFMS0NMNnF6eFNLNDMwNGtCbjNfSSIsICJ6VTQ1MmxrR2JFS2g4WnVIXzhLeDNDVXZuMUY0eTFnWkxxbERUZ1hfOFBrIl0sICJpc3MiOiAiaHR0cHM6Ly9waWQtcHJvdmlkZXIubWVtYmVyc3RhdGUuZXhhbXBsZS5ldSIsICJpYXQiOiAxNTQxNDkzNzI0LCAiZXhwIjogMTg4MzAwMDAwMCwgInR5cGUiOiAiUGVyc29uSWRlbnRpZmljYXRpb25EYXRhIiwgIl9zZF9hbGciOiAic2hhLTI1NiIsICJjbmYiOiB7Imp3ayI6IHsia3R5IjogIkVDIiwgImNydiI6ICJQLTI1NiIsICJ4IjogIlRDQUVSMTladnUzT0hGNGo0VzR2ZlNWb0hJUDFJTGlsRGxzN3ZDZUdlbWMiLCAieSI6ICJaeGppV1diWk1RR0hWV0tWUTRoYlNJaXJzVmZ1ZWNDRTZ0NGpUOUYySFpRIn19fQ.9hyAKjlth_-BLWKYWkzg-oshIAKIauwC-y8w-a2bWyPGnZ8SE9ijvDEPEdddIi2EFJlt76fK-vN2QcMLCrNR7Q~WyIyR0xDNDJzS1F2ZUNmR2ZyeU5STjl3IiwgImZpcnN0X25hbWUiLCAiRXJpa2EiXQ~WyJlbHVWNU9nM2dTTklJOEVZbnN4QV9BIiwgImZhbWlseV9uYW1lIiwgIk11c3Rlcm1hbm4iXQ~WyI2SWo3dE0tYTVpVlBHYm9TNXRtdlZBIiwgIkRFIl0~WyJlSThaV205UW5LUHBOUGVOZW5IZGhRIiwgIm5hdGlvbmFsaXRpZXMiLCBbeyIuLi4iOiAiSnVMMzJRWER6aXpsLUw2Q0xyZnhmanBac1gzTzZ2c2ZwQ1ZkMWprd0pZZyJ9XV0~WyJRZ19PNjR6cUF4ZTQxMmExMDhpcm9BIiwgImJpcnRoX2ZhbWlseV9uYW1lIiwgIlNjaG1pZHQiXQ~WyJBSngtMDk1VlBycFR0TjRRTU9xUk9BIiwgImJpcnRoZGF0ZSIsICIxOTczLTAxLTAxIl0~WyJQYzMzSk0yTGNoY1VfbEhnZ3ZfdWZRIiwgImFkZHJlc3MiLCB7InBvc3RhbF9jb2RlIjogIjEyMzQ1IiwgImxvY2FsaXR5IjogIklyZ2VuZHdvIiwgInN0cmVldF9hZGRyZXNzIjogIlNvbm5lbnN0cmFzc2UgMjMiLCAiY291bnRyeV9jb2RlIjogIkRFIn1d~WyJHMDJOU3JRZmpGWFE3SW8wOXN5YWpBIiwgImlzX292ZXJfMTgiLCB0cnVlXQ~WyJsa2x4RjVqTVlsR1RQVW92TU5JdkNBIiwgImlzX292ZXJfMjEiLCB0cnVlXQ~WyJuUHVvUW5rUkZxM0JJZUFtN0FuWEZBIiwgImlzX292ZXJfNjUiLCBmYWxzZV0~"

local credential = {
    _sd = {
        "0n9yzFSWvK_BUHiaMhm12ghrCtVahrGJ6_-kZP-ySq4",
        "Ch-DBcL3kb4VbHIwtknnZdNUHthEq9MZjoFdg6idiho",
        "DW7gFVZSuyr42YSYx8p8rVKEktJzJ3uFImenmJBImds",
        "I00fcFUoDXCucp5yy2ujqPssDVGaWNiUliNz_awD0gc",
        "X9MaPaFWmQYpfHEdytRdaclnYoEru8EztBEUQuWOe44",
        "d8qkfPdoe2PYE93d5M_gBL1gZlpFRKCc0d1laod__s0",
        "lI3L0hseCRWmUPg82VCUN_a17sML_64QgA4JFTYDFDE",
        "puMpGLoAGRbcsAg50UZ0hhQLKCL6qzxSK4304kBn3_I",
        "zU452lkGbEKh8ZuH_8Kx3CUvn1F4y1gZLqlDTgX_8Pk"
    },
    iss = "https://pid-provider.memberstate.example.eu",
    iat = 1541493724,
    exp = 1883000000,
    type = "PersonIdentificationData",
    _sd_alg = "sha-256",
    cnf = {
        jwk = {
            kty = "EC",
            crv = "P-256",
            x = "TCAER19Zvu3OHF4j4W4vfSVoHIP1ILilDls7vCeGemc",
            y = "ZxjiWWbZMQGHVWKVQ4hbSIirsVfuecCE6t4jT9F2HZQ"
        }
    }
}

--[[
   output = {
    _sd = [9] { "rdAtIF5vLGtmEhLfOWDO9eK5-Xp9KAcU4hD1LhhPIys", "HHnWy6hXvgobfRXaxMuWjjw08l05cQHPT4FRRWuFHWI", "llhMgM5MGIxg5en77m8Nxl2-Dpxg4rbSo9MPNTlHY1w", "0lonm8X8CoHrj4lbeBbfajy3z86LrqiCf_sgdresM2c", "k2TVvZiJV3ZDOQgOUYmNwOa3Zm1g7kBwkMz3K_pfet8", "mfV7QfVRYElMS2qRLkYqGEC8C8xC8oGkD6345_6wFpQ", "MmJcUxSuqrFdtLNh22tv-DUXFiQ-SxisOBRUa1-Gtm0", "raEzOttFk-mpSAZinYY-VBMMY4oemU7H6VQi0t3X3rs", "xJxvy-vsRhwFVngc7X_p8hdkWkeMjcshdvRYUfCMlYY" },
    _sd_alg = "sha-256",
    cnf = {
        jwk = {
            crv = "P-256",
            kty = "EC",
            x = "TCAER19Zvu3OHF4j4W4vfSVoHIP1ILilDls7vCeGemc",
            y = "ZxjiWWbZMQGHVWKVQ4hbSIirsVfuecCE6t4jT9F2HZQ"
        }
    },
    exp = 1883000000,
    iat = 1541493724,
    iss = "https://pid-provider.memberstate.example.eu",
    typ = "PersonIdentificationData"
}
--]]
local function export_str_dict(obj)
    return deepmap(get_encoding_function("string"), obj)
end

local jwt = SD_JWT.create_sd(test_sdr)
local payload = export_str_dict(jwt.payload)
I.spy(payload)
print("Test Disclosed Claims")
assert(payload, "Error in decoding")
assert(payload._sd_alg == credential._sd_alg, "Error in hash algorithm")
assert(payload.iat == credential.iat, "Error in claim IssuedAt")
assert(payload.exp == credential.exp, "Error in claim ExpirationDate")
assert(payload.iss == credential.iss, "Error in claim Issuer")
assert(payload.type == credential.type, "Error in claim CredentialType")

-- The following is used to check that if we use the same salt, we obtain the same _sd array 

-- Claim first_name
-- Claim family_name
-- Array Entry: deeper level disclosure not yet implemented
-- Claim nationalities
-- Claim birth_family_name
-- Claim birthdate
-- Claim address: same problem as the array in previous test
-- Claim is_over_18
-- Claim is_over_21
-- Claim is_over_65

local hash = {
    "Ch-DBcL3kb4VbHIwtknnZdNUHthEq9MZjoFdg6idiho",
    "I00fcFUoDXCucp5yy2ujqPssDVGaWNiUliNz_awD0gc",
    "JuL32QXDzizl-L6CLrfxfjpZsX3O6vsfpCVd1jkwJYg",
    --"zU452lkGbEKh8ZuH_8Kx3CUvn1F4y1gZLqlDTgX_8Pk",
    "X9MaPaFWmQYpfHEdytRdaclnYoEru8EztBEUQuWOe44",
    "0n9yzFSWvK_BUHiaMhm12ghrCtVahrGJ6_-kZP-ySq4",
    --"d8qkfPdoe2PYE93d5M_gBL1gZlpFRKCc0d1laod__s0",
    "puMpGLoAGRbcsAg50UZ0hhQLKCL6qzxSK4304kBn3_I",
    "lI3L0hseCRWmUPg82VCUN_a17sML_64QgA4JFTYDFDE",
    "DW7gFVZSuyr42YSYx8p8rVKEktJzJ3uFImenmJBImds",
}

local disclosure = {
    "WyIyR0xDNDJzS1F2ZUNmR2ZyeU5STjl3IiwgImZpcnN0X25hbWUiLCAiRXJpa2EiXQ",
    "WyJlbHVWNU9nM2dTTklJOEVZbnN4QV9BIiwgImZhbWlseV9uYW1lIiwgIk11c3Rlcm1hbm4iXQ",
    "WyI2SWo3dE0tYTVpVlBHYm9TNXRtdlZBIiwgIkRFIl0",
    --"WyJlSThaV205UW5LUHBOUGVOZW5IZGhRIiwgIm5hdGlvbmFsaXRpZXMiLCBbeyIuLi4iOiAiSnVMMzJRWER6aXpsLUw2Q0xyZnhmanBac1gzTzZ2c2ZwQ1ZkMWprd0pZZyJ9XV0",
    "WyJRZ19PNjR6cUF4ZTQxMmExMDhpcm9BIiwgImJpcnRoX2ZhbWlseV9uYW1lIiwgIlNjaG1pZHQiXQ",
    "WyJBSngtMDk1VlBycFR0TjRRTU9xUk9BIiwgImJpcnRoZGF0ZSIsICIxOTczLTAxLTAxIl0",
    --"WyJQYzMzSk0yTGNoY1VfbEhnZ3ZfdWZRIiwgImFkZHJlc3MiLCB7InBvc3RhbF9jb2RlIjogIjEyMzQ1IiwgImxvY2FsaXR5IjogIklyZ2VuZHdvIiwgInN0cmVldF9hZGRyZXNzIjogIlNvbm5lbnN0cmFzc2UgMjMiLCAiY291bnRyeV9jb2RlIjogIkRFIn1d",
    "WyJHMDJOU3JRZmpGWFE3SW8wOXN5YWpBIiwgImlzX292ZXJfMTgiLCB0cnVlXQ",
    "WyJsa2x4RjVqTVlsR1RQVW92TU5JdkNBIiwgImlzX292ZXJfMjEiLCB0cnVlXQ",
    "WyJuUHVvUW5rUkZxM0JJZUFtN0FuWEZBIiwgImlzX292ZXJfNjUiLCBmYWxzZV0",
}

local content = {
    {"2GLC42sKQveCfGfryNRN9w", "first_name", "Erika"},
    {"eluV5Og3gSNII8EYnsxA_A", "family_name", "Mustermann"},
    {"6Ij7tM-a5iVPGboS5tmvVA", "DE"},
    --{"eI8ZWm9QnKPpNPeNenHdhQ", "nationalities", {{"...": "JuL32QXDzizl-L6CLrfxfjpZsX3O6vsfpCVd1jkwJYg"}}},
    {"Qg_O64zqAxe412a108iroA", "birth_family_name", "Schmidt"},
    {"AJx-095VPrpTtN4QMOqROA", "birthdate", "1973-01-01"},
    --{"Pc33JM2LchcU_lHggv_ufQ", "address", {postal_code = "12345", locality = "Irgendwo", street_address = "Sonnenstrasse 23", country_code = "DE"}},
    {"G02NSrQfjFXQ7Io09syajA", "is_over_18", true},
    {"lklxF5jMYlGTPUovMNIvCA", "is_over_21", true},
    {"nPuoQnkRFq3BIeAm7AnXFA", "is_over_65", false},
}

print("Test Disclosures 2")
for i = 1, #content do
    print("Test case "..i)
    local _, hashd, dis = SD_JWT.create_disclosure(content[i])

    zencode_assert(dis == disclosure[i], "Wrong disclosure")
    zencode_assert(hashd == O.from_string(hash[i]), "Wrong hash")
end
