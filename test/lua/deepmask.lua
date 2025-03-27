-- Test data
local test_data = {
    name = "Alice",
    secret = "my secret message",
    nested = {
        code = "nested code",
        crypto = {
            key = "secret key",
            iv = "initialization vector"
        }
    },
    binary = OCTET.from_string("binary data"),
    encoded = OCTET.from_string("to be encoded")
}

-- Mask with transformation functions
local mask = {
    secret = function(v) return sha256(OCTET.from_string(v)):to_mnemonic() end,
    nested = {
        crypto = {
            key = function(v) return OCTET.from_string(v):to_base64() end,
            iv = function(v) return OCTET.from_string(v):to_hex() end
        }
    },
    binary = function(v) return v:to_array() end,
    encoded = function(v) return v:to_base58() end
}

-- Default function (applied when no mask is found)
local default_func = function(v, k)
    return v
end

-- Test the function
local transformed = deepmask(default_func, test_data, mask)

assert(JSON.encode(transformed)=='{"binary":[98.0,105.0,110.0,97.0,114.0,121.0,32.0,100.0,97.0,116.0,97.0],"encoded":"AhVCQPry2svggZcn5H","name":"Alice","nested":{"code":"nested code","crypto":{"iv":"696e697469616c697a6174696f6e20766563746f72","key":"c2VjcmV0IGtleQ=="}},"secret":"onion canoe strategy minor rookie route extend cause lunar cheap drive near illness pill medal save toss athlete pattern avocado east excuse impose insect"}')


local test_data_2 = {
    user = {
        id = "user_12345",
        profile = {
            name = "John Doe",
            contacts = {
                email = "john@example.com",
                phone = "+1234567890",
                social = {
                    twitter = "@johndoe",
                    github = "johndoe"
                }
            },
            auth = {
                password = "s3cr3tP@ss",
                tokens = {
                    access = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
                    refresh = "refresh_token_xyz"
                }
            }
        },
        preferences = {
            theme = "dark",
            notifications = true
        }
    },
    system = {
        config = {
            version = "1.2.3",
            keys = {
                public = "MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAKx",
                private = "MIIBOwIBAAJBAKx3q6W5Z6JQOeJN"
            }
        },
        stats = {
            uptime = 3600,
            requests = 1024
        }
    },
    binary_data = {
        image = OCTET.from_string("PNG...binary...data"),
        signature = OCTET.from_string("SIGNATURE_DATA")
    }
}

local mask_2 = {
    user = {
        profile = {
            contacts = {
                phone = function(v) return "***" .. v:sub(-4) end,
                social = {
                    twitter = function(v) return v:upper() end
                }
            },
            auth = {
                password = function() return "[REDACTED]" end,
                tokens = {
                    access = function(v)
                        local part = OCTET.from_string(v):sub(1,6)
                        return part .. "..."
                    end,
                    refresh = function(v) return OCTET.from_string(v):to_base64() end
                }
            }
        }
    },
    system = {
        config = {
            keys = {
                public = function(v) return v:sub(1, 8) .. "..." end,
                private = function() return "[CONFIDENTIAL]" end
            }
        },
        stats = {
            uptime = function(v) return ("%02d:%02d:%02d"):format(v/3600, (v%3600)/60, v%60) end
        }
    },
    binary_data = {
        image = function(v) return v:to_base64() end,
        signature = function(v)
            local o = { val = v:to_hex(),
                        t = "secure_hex"}
            return o
        end
    }
}

local transformed_2 = deepmask(default_func, test_data_2, mask_2)
assert(JSON.encode(transformed_2)=='{"binary_data":{"image":"UE5HLi4uYmluYXJ5Li4uZGF0YQ==","signature":{"t":"secure_hex","val":"5349474e41545552455f44415441"}},"system":{"config":{"keys":{"private":"[CONFIDENTIAL]","public":"MFwwDQYJ..."},"version":"1.2.3"},"stats":{"requests":1024,"uptime":"01:00:00"}},"user":{"id":"user_12345","preferences":{"notifications":true,"theme":"dark"},"profile":{"auth":{"password":"[REDACTED]","tokens":{"access":"ZXlKaGJHLi4u","refresh":"cmVmcmVzaF90b2tlbl94eXo="}},"contacts":{"email":"john@example.com","phone":"***7890","social":{"github":"johndoe","twitter":"@JOHNDOE"}},"name":"John Doe"}}}')
