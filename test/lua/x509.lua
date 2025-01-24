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

KEY = [[
-----BEGIN EC PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgB648VWj7/K+tQ4eZ
82blPBV4jwi1qSCWWIyT7xf3J0OhRANCAATUtxD9sLQNnsl2eLtW58u7RI5e6CB9
nHA3aGAMZrI6hZBzU04KoxyteoM/f5RbCTFjcGFby66D6xyciBDFFkXn
-----END EC PRIVATE KEY-----
]]

x509 = require'x509'
P256 = require('es256')

pem = OCTET.from_base64(x509.pem_to_base64(CERT))
I.print({PEM=pem})
cert = x509.extract_cert(pem)
sig = x509.extract_cert_sig(pem)
pk = x509.extract_pubkey(cert)
I.print({cert=cert, sig=sig, pubkey=pk})

issuer = x509.extract_issuer(cert)
I.print({issuer=issuer})

subj = x509.extract_subject(cert)
I.print({subject=subj})

-- ext = x509.extract_extensions(cert)
-- I.print({extensions=ext,
--          san_hex=OCTET.from_string(ext.SAN):hex()})

san = x509.extract_san(cert)
I.print({SAN=san})

dates = x509.extract_dates(cert)
I.print({dates=dates})

assert( P256.verify(pk,cert,sig) )

key = x509.extract_seckey(
    OCTET.from_base64(x509.pem_to_base64(KEY))
)
assert( P256.pubgen(key) == pk)
