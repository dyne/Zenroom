-- Lua tests for multiformats like multibase
-- defined in src/lua/zenroom_common.lua


-- from https://github.com/multiformats/multibase
orig = O.from_hex'4D756C74696261736520697320617765736F6D6521205C6F2F'
-- JV2WY5DJMJQXGZJANFZSAYLXMVZW63LFEEQFY3ZP           # base32
-- 3IY8QKL64VUGCX009XWUHKF6GBBTS3TVRXFRA5R            # base36
-- TZ9:VDNEDHECDZC+ED944A4FVQEF$DK84%UB21             # base45
-- YAjKoNbau5KiqmHPmSxYCvn66dA1vLmwbt                 # base58
-- TXVsdGliYXNlIGlzIGF3ZXNvbWUhIFxvLw==               # base64

assert(orig == multibase_decode'F4D756C74696261736520697320617765736F6D6521205C6F2F')
assert(orig == multibase_decode'RTZ9:VDNEDHECDZC+ED944A4FVQEF$DK84%UB21')
assert(orig == multibase_decode'zYAjKoNbau5KiqmHPmSxYCvn66dA1vLmwbt')
assert(orig == multibase_decode'MTXVsdGliYXNlIGlzIGF3ZXNvbWUhIFxvLw==')
