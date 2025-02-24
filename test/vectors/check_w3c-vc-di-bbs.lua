-- doc: https://www.w3.org/TR/vc-di-bbs/

local bbs = require'crypto_bbs'
local ciphersuite = bbs.ciphersuite('sha256')

function signatureControls(ciphersuite, vector_privateKey, vector_publicKey, vector_bbsSignature, vector_proofHash, vector_mandatoryHash, vector_bbsMessages)
    local vector_header = vector_proofHash .. vector_mandatoryHash

    -- test if zenroom does verify the bbs signature vector
    assert(bbs.verify(ciphersuite, O.from_hex(vector_publicKey), O.from_hex(vector_bbsSignature), O.from_hex(vector_header), vector_bbsMessages) == true, "unable to verify a valid signature")

    -- test the possibility to produce via zenroom a valid bbs-vc signature following the documentation procedure
    bbsSignature = bbs.sign(ciphersuite, BIG.new(O.from_hex(vector_privateKey)), O.from_hex(vector_publicKey), O.from_hex(vector_header), vector_bbsMessages)
    assert(O.to_hex(bbsSignature) == vector_bbsSignature, "the bbs signature produced is incorrect")
end


-- vector: A.1 Baseline Basic Example
local vector_publicKey = "a4ef1afa3da575496f122b9b78b8c24761531a8a093206ae7c45b80759c168ba4f7a260f9c3367b6c019b4677841104b10665edbe70ba3ebe7d9cfbffbf71eb016f70abfbb163317f372697dc63efd21fc55764f63926a8f02eaea325a2a888f"
local vector_privateKey = "66d36e118832af4c5e28b2dfe1b9577857e57b042a33e06bdea37b811ed09ee0"
local vector_proofHash = "3a5bbf25d34d90b18c35cd2357be6a6f42301e94fc9e52f77e93b773c5614bdf"
local vector_mandatoryHash = "8e7cc22c318dd2094e02d0bf06c5d73a5dba717611a40f6d1bedc5ea7c300fd6"
local vector_bbsMessages = {
    O.from_str('_:b0 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://schema.org/Person> .\n'),
    O.from_str('_:b0 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/citizenship#PermanentResident> .\n'),
    O.from_str('_:b0 <https://schema.org/birthDate> "1978-07-17"^^<http://www.w3.org/2001/XMLSchema#dateTime> .\n'),
    O.from_str('_:b0 <https://schema.org/familyName> "SMITH" .\n'),
    O.from_str('_:b0 <https://schema.org/gender> "Female" .\n'),
    O.from_str('_:b0 <https://schema.org/givenName> "JANE" .\n'),
    O.from_str('_:b0 <https://schema.org/image> <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIW2P4v43hPwAHIgK1v4tX6wAAAABJRU5ErkJggg==> .\n'),
    O.from_str('_:b0 <https://w3id.org/citizenship#birthCountry> "Arcadia" .\n'),
    O.from_str('_:b0 <https://w3id.org/citizenship#commuterClassification> "C1" .\n'),
    O.from_str('_:b0 <https://w3id.org/citizenship#permanentResidentCard> _:b1 .\n'),
    O.from_str('_:b0 <https://w3id.org/citizenship#residentSince> "2015-01-01"^^<http://www.w3.org/2001/XMLSchema#dateTime> .\n'),
    O.from_str('_:b1 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/citizenship#PermanentResidentCard> .\n'),
    O.from_str('_:b1 <https://schema.org/identifier> "83627465" .\n'),
    O.from_str('_:b1 <https://w3id.org/citizenship#lprCategory> "C09" .\n'),
    O.from_str('_:b1 <https://w3id.org/citizenship#lprNumber> "999-999-999" .\n'),
    O.from_str('_:b2 <https://schema.org/description> "Permanent Resident Card from Government of Utopia." .\n'),
    O.from_str('_:b2 <https://schema.org/name> "Permanent Resident Card" .\n'),
    O.from_str('_:b2 <https://www.w3.org/2018/credentials#credentialSubject> _:b0 .\n'),
    O.from_str('_:b2 <https://www.w3.org/2018/credentials#validFrom> "2024-12-16T00:00:00Z"^^<http://www.w3.org/2001/XMLSchema#dateTime> .\n'),
    O.from_str('_:b2 <https://www.w3.org/2018/credentials#validUntil> "2025-12-16T23:59:59Z"^^<http://www.w3.org/2001/XMLSchema#dateTime> .\n')
}
local vector_bbsSignature = "86168dd2b5d0c7c6a56a30f4212ed116a53def05d0d6708207d483c7ff2053aefa22d24ba7659d60852694f8d85be0fa2adc3974c7dc4cc68b3db17b2423975047104162c24502b41591879ac24f1bb1"

-- tests for A.1.1 Base Proof
signatureControls(ciphersuite, vector_privateKey, vector_publicKey, vector_bbsSignature, vector_proofHash, vector_mandatoryHash, vector_bbsMessages)
-- to be done: tests for A.1.2 Derived Proof
-- proofControls( ... )

-- A.2 Baseline Enhanced Example
vector_publicKey = "a4ef1afa3da575496f122b9b78b8c24761531a8a093206ae7c45b80759c168ba4f7a260f9c3367b6c019b4677841104b10665edbe70ba3ebe7d9cfbffbf71eb016f70abfbb163317f372697dc63efd21fc55764f63926a8f02eaea325a2a888f"
vector_privateKey = "66d36e118832af4c5e28b2dfe1b9577857e57b042a33e06bdea37b811ed09ee0"
vector_proofHash = "3a5bbf25d34d90b18c35cd2357be6a6f42301e94fc9e52f77e93b773c5614bdf"
vector_mandatoryHash = "555de05f898817e31301bac187d0c3ff2b03e2cbdb4adb4d568c17de961f9a18"
vector_bbsMessages = {
    O.from_str('_:b1 <https://windsurf.grotto-networking.com/selective#sailName> "Lahaina" .\n'),
    O.from_str('_:b1 <https://windsurf.grotto-networking.com/selective#size> "7.8E0"^^<http://www.w3.org/2001/XMLSchema#double> .\n'),
    O.from_str('_:b1 <https://windsurf.grotto-networking.com/selective#year> "2023"^^<http://www.w3.org/2001/XMLSchema#integer> .\n'),
    O.from_str('_:b2 <https://windsurf.grotto-networking.com/selective#boardName> "CompFoil170" .\n'),
    O.from_str('_:b2 <https://windsurf.grotto-networking.com/selective#brand> "Wailea" .\n'),
    O.from_str('_:b3 <https://windsurf.grotto-networking.com/selective#boards> _:b4 .\n'),
    O.from_str('_:b3 <https://windsurf.grotto-networking.com/selective#sails> _:b1 .\n'),
    O.from_str('_:b3 <https://windsurf.grotto-networking.com/selective#sails> _:b5 .\n'),
    O.from_str('_:b4 <https://windsurf.grotto-networking.com/selective#boardName> "Kanaha Custom" .\n'),
    O.from_str('_:b4 <https://windsurf.grotto-networking.com/selective#brand> "Wailea" .\n'),
    O.from_str('_:b4 <https://windsurf.grotto-networking.com/selective#year> "2019"^^<http://www.w3.org/2001/XMLSchema#integer> .\n'),
    O.from_str('_:b5 <https://windsurf.grotto-networking.com/selective#sailName> "Kihei" .\n'),
    O.from_str('_:b5 <https://windsurf.grotto-networking.com/selective#size> "5.5E0"^^<http://www.w3.org/2001/XMLSchema#double> .\n'),
    O.from_str('_:b5 <https://windsurf.grotto-networking.com/selective#year> "2023"^^<http://www.w3.org/2001/XMLSchema#integer> .\n')
}
vector_bbsSignature = "8331f55ad458fe5c322420b2cb806f9a20ea6b2b8a29d51710026d71ace5da080064b488818efc75a439525bd031450822a6a332da781926e19360b90166431124efcf3d060fbc750c6122c714c07f71"

-- tests for A.2.1 Base Proof
signatureControls(ciphersuite, vector_privateKey, vector_publicKey, vector_bbsSignature, vector_proofHash, vector_mandatoryHash, vector_bbsMessages)
-- to be done: tests for A.2.2 Derived Proof
-- proofControls( ... )