CERT = [[
-----BEGIN CERTIFICATE-----
MIIB5zCCAY2gAwIBAgIBATAKBggqhkjOPQQDAjAgMR4wHAYDVQQDDBVEaWRyb29t
IC0gbWF0dGVvIPCfm7gwHhcNMjUwMTIwMDg1ODEwWhcNMjYwMTIxMDg1ODEwWjAg
MR4wHAYDVQQDDBVEaWRyb29tIC0gbWF0dGVvIPCfm7gwWTATBgcqhkjOPQIBBggq
hkjOPQMBBwNCAATUtxD9sLQNnsl2eLtW58u7RI5e6CB9nHA3aGAMZrI6hZBzU04K
oxyteoM/f5RbCTFjcGFby66D6xyciBDFFkXno4G3MIG0MBIGA1UdEwEB/wQIMAYB
Af8CAQIwHAYDVR0lAQH/BBIwEAYGKgMEBQYHBgZTBAUGBwgwDgYDVR0PAQH/BAQD
AgEGMB0GA1UdDgQWBBTuz5prI2WpFQJjXzyTu7ZUhj0/QjBRBgNVHREESjBIhkZk
aWQ6ZHluZTpzYW5kYm94LnNpZ25yb29tOjRLRXltV2dMRFVmMUxOY2tleFk5NmRm
S3o1dkg3OWRpRGVrZ0xNUjlGV3BIMAoGCCqGSM49BAMCA0gAMEUCIQCVetesj1HI
U43l7wzHuj+lX5ZJA9P019HuGazQA3RTVgIgSHXU5Brj7rSaBBUdY8uBdKPE/h0Z
oBqKuv/u9Qf8mdM=
-----END CERTIFICATE-----
]]

local x509 = require'x509'

local pem_with_nul = "-----BEGIN CERTIFICATE-----\nQQ==\n" .. string.char(0) .. "-----END CERTIFICATE-----\n"
assert(x509.pem_to_base64(pem_with_nul) == "QQ==")

local cert = x509.extract_cert(OCTET.from_base64(x509.pem_to_base64(CERT)))
local cert_hex = cert:hex()

local san_payload = "6469643a64796e653a73616e64626f782e7369676e726f6f6d3a344b45796d57674c445566314c4e636b657859393664664b7a3576483739646944656b674c4d523946577048"
local nul_payload = "61620063" .. string.rep("41", 66)
local cert_with_nul_san = OCTET.from_hex(cert_hex:gsub(san_payload, nul_payload, 1))
local san = x509.extract_san(cert_with_nul_san)
assert(san[1].type == "url")
assert(#san[1].data == 70)
assert(string.byte(san[1].data, 3) == 0)

local malformed_san_cert = OCTET.from_hex(cert_hex:gsub("0603551d11044a30488646", "0603551d11044a3048867f", 1))
local ok, err = pcall(x509.extract_san, malformed_san_cert)
assert(not ok)
assert(string.find(err, "Malformed SAN", 1, true))
