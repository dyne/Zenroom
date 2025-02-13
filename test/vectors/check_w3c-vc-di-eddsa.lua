--  w3c EDDSA Ed25519 signature vector verification. Specification source: https://www.w3.org/TR/vc-di-eddsa

ED = require('ed')

function O_from_multibase58(mut58_str)
    -- Remove the base 58 encoding prefix character from the string
    local prefix = mut58_str:sub(1,1)
    assert(prefix == 'z', 'Error, multibase conversion not valid, bad multibase58 value')
    local unprefixed_str = mut58_str:sub(2)
    return  O.from_base58(unprefixed_str)
end

-- return hex compressed pk starting from a eddsa multikey (designed only to work with Ed25519 256, no other cases considered)
function mulikey_to_hex(str) 
    -- remove multibase58 encoding
    local O_multikey = O_from_multibase58(str)

    -- Remove the two-byte prefix character of eddsa keys from the string
    local hex_multikey = O.to_hex(O_multikey)
    local prefix = hex_multikey:sub(1,4)
    assert(prefix=='ed01' or prefix=='8026', 'Error. multikey convertion function called on a non eddsa Ed25519 256 key')
    local compressed_pk= hex_multikey:sub(5)
    
    return compressed_pk
end


function controls(vector_m1 ,vector_m2, vector_h1, vector_h2, vector_multikey_pk, vector_multikey_sk, vector_m, vector_sg)
    print("Run test to verify signature and public key of w3c eddsa-vc")
    -- multibase and multikey vectors conversions
    local vector_pk = O.from_hex(mulikey_to_hex(vector_multikey_pk))
    local vector_sk = O.from_hex(mulikey_to_hex(vector_multikey_sk)) 

    -- [0] test if zenroom does verify the eddsa vector provided signature
    assert(ED.verify(vector_pk, vector_sg, vector_m), "error in the EdDSA verification function; it is unable to validate the test vector.")

    -- [1] test hash correctness 
    local h1 = O.to_hex(sha256(vector_m1)) 
    assert(vector_h1 == h1, "hash and vector hash of Canonical Proof Options Document doesn't match")

    local h2 = O.to_hex(sha256(vector_m2)) 
    assert(vector_h2 == h2, "hash and vector hash of Canonical Credential without Proof doesn't match")

    -- [2] test if zenroom produced pk matches w3c vector pk
    local pk = ED.pubgen(vector_sk)
    assert(vector_pk == pk, "EdDSA zenroom generated pk does not match the w3c test vector pk")
    
    -- [3] test the possibility to produce via zenroom a valid eddsa-vc following the documentation procedure
    local m = O.from_hex(h1 .. h2)
    assert(vector_m == m, "the message produced to be signed does not match the test vector message")
    local sg = ED.sign(vector_sk, m)
    assert(vector_sg == sg, "eddsa verify failed, incorrect signature")    
end




-- vector: B.1 Representation: eddsa-rdfc-2022
local vector_m2_CanonicalCredential = O.from_str([[<did:example:abcdefgh> <https://www.w3.org/ns/credentials/examples#alumniOf> "The School of Examples" .
<urn:uuid:58172aac-d8ba-11ed-83dd-0b3aef56cc33> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.w3.org/2018/credentials#VerifiableCredential> .
<urn:uuid:58172aac-d8ba-11ed-83dd-0b3aef56cc33> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.w3.org/ns/credentials/examples#AlumniCredential> .
<urn:uuid:58172aac-d8ba-11ed-83dd-0b3aef56cc33> <https://schema.org/description> "A minimum viable example of an Alumni Credential." .
<urn:uuid:58172aac-d8ba-11ed-83dd-0b3aef56cc33> <https://schema.org/name> "Alumni Credential" .
<urn:uuid:58172aac-d8ba-11ed-83dd-0b3aef56cc33> <https://www.w3.org/2018/credentials#credentialSubject> <did:example:abcdefgh> .
<urn:uuid:58172aac-d8ba-11ed-83dd-0b3aef56cc33> <https://www.w3.org/2018/credentials#issuer> <https://vc.example/issuers/5678> .
<urn:uuid:58172aac-d8ba-11ed-83dd-0b3aef56cc33> <https://www.w3.org/2018/credentials#validFrom> "2023-01-01T00:00:00Z"^^<http://www.w3.org/2001/XMLSchema#dateTime> .
]])
local vector_m1_CanonicalProofOptions = O.from_str([[_:c14n0 <http://purl.org/dc/terms/created> "2023-02-24T23:36:38Z"^^<http://www.w3.org/2001/XMLSchema#dateTime> .
_:c14n0 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/security#DataIntegrityProof> .
_:c14n0 <https://w3id.org/security#cryptosuite> "eddsa-rdfc-2022"^^<https://w3id.org/security#cryptosuiteString> .
_:c14n0 <https://w3id.org/security#proofPurpose> <https://w3id.org/security#assertionMethod> .
_:c14n0 <https://w3id.org/security#verificationMethod> <did:key:z6MkrJVnaZkeFzdQyMZu1cgjg7k1pZZ6pvBQ7XJPt4swbTQ2#z6MkrJVnaZkeFzdQyMZu1cgjg7k1pZZ6pvBQ7XJPt4swbTQ2> .
]])
local vector_h2 = '517744132ae165a5349155bef0bb0cf2258fff99dfe1dbd914b938d775a36017'
local vector_h1 = 'bea7b7acfbad0126b135104024a5f1733e705108f42d59668b05c0c50004c6b0'
local vector_multikey_pk = 'z6MkrJVnaZkeFzdQyMZu1cgjg7k1pZZ6pvBQ7XJPt4swbTQ2'
local vector_multikey_sk = 'z3u2en7t5LR2WtQH5PfFqMqwVHBeXouLzo6haApm8XHqvjxq'  
local vector_m = O.from_hex('bea7b7acfbad0126b135104024a5f1733e705108f42d59668b05c0c50004c6b0517744132ae165a5349155bef0bb0cf2258fff99dfe1dbd914b938d775a36017')
local vector_sg = O.from_hex('4d8e53c2d5b3f2a7891753eb16ca993325bdb0d3cfc5be1093d0a18426f5ef8578cadc0fd4b5f4dd0d1ce0aefd15ab120b7a894d0eb094ffda4e6553cd1ed50d')

controls(vector_m1_CanonicalProofOptions ,vector_m2_CanonicalCredential, vector_h1, 
        vector_h2, vector_multikey_pk, vector_multikey_sk, vector_m, vector_sg)



-- vector: B.2 Enhanced Example... deb: continue
vector_m2_CanonicalCredential = O.from_str([[<did:key:zDnaegE6RR3atJtHKwTRTWHsJ3kNHqFwv7n9YjTgmU7TyfU76> <https://schema.org/image> <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIW2NgUPr/HwADaAIhG61j/AAAAABJRU5ErkJggg==> .
_:c14n0 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/citizenship#EmploymentAuthorizationDocumentCredential> .
_:c14n0 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.w3.org/2018/credentials#VerifiableCredential> .
_:c14n0 <https://schema.org/description> "Example Employment Authorization Document." .
_:c14n0 <https://schema.org/name> "Employment Authorization Document" .
_:c14n0 <https://www.w3.org/2018/credentials#credentialSubject> _:c14n1 .
_:c14n0 <https://www.w3.org/2018/credentials#issuer> <did:key:zDnaegE6RR3atJtHKwTRTWHsJ3kNHqFwv7n9YjTgmU7TyfU76> .
_:c14n0 <https://www.w3.org/2018/credentials#validFrom> "2019-12-03T00:00:00Z"^^<http://www.w3.org/2001/XMLSchema#dateTime> .
_:c14n0 <https://www.w3.org/2018/credentials#validUntil> "2029-12-03T00:00:00Z"^^<http://www.w3.org/2001/XMLSchema#dateTime> .
_:c14n1 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://schema.org/Person> .
_:c14n1 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/citizenship#EmployablePerson> .
_:c14n1 <https://schema.org/additionalName> "JACOB" .
_:c14n1 <https://schema.org/birthDate> "1999-07-17"^^<http://www.w3.org/2001/XMLSchema#dateTime> .
_:c14n1 <https://schema.org/familyName> "SMITH" .
_:c14n1 <https://schema.org/gender> "Male" .
_:c14n1 <https://schema.org/givenName> "JOHN" .
_:c14n1 <https://schema.org/image> <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIW2Ng+M/wHwAEAQH/7yMK/gAAAABJRU5ErkJggg==> .
_:c14n1 <https://w3id.org/citizenship#birthCountry> "Bahamas" .
_:c14n1 <https://w3id.org/citizenship#employmentAuthorizationDocument> _:c14n2 .
_:c14n1 <https://w3id.org/citizenship#residentSince> "2015-01-01"^^<http://www.w3.org/2001/XMLSchema#dateTime> .
_:c14n2 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/citizenship#EmploymentAuthorizationDocument> .
_:c14n2 <https://schema.org/identifier> "83627465" .
_:c14n2 <https://w3id.org/citizenship#lprCategory> "C09" .
_:c14n2 <https://w3id.org/citizenship#lprNumber> "999-999-999" .
]])
vector_m1_CanonicalProofOptions = O.from_str([[_:c14n0 <http://purl.org/dc/terms/created> "2023-02-24T23:36:38Z"^^<http://www.w3.org/2001/XMLSchema#dateTime> .
_:c14n0 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/security#DataIntegrityProof> .
_:c14n0 <https://w3id.org/security#cryptosuite> "eddsa-rdfc-2022"^^<https://w3id.org/security#cryptosuiteString> .
_:c14n0 <https://w3id.org/security#proofPurpose> <https://w3id.org/security#assertionMethod> .
_:c14n0 <https://w3id.org/security#verificationMethod> <did:key:z6MkrJVnaZkeFzdQyMZu1cgjg7k1pZZ6pvBQ7XJPt4swbTQ2#z6MkrJVnaZkeFzdQyMZu1cgjg7k1pZZ6pvBQ7XJPt4swbTQ2> .
]])
vector_h2 = '03f59e5b04ab575b1172cb684f22eede72f0e9033e0b5c67d0e2506768d6ce11'
vector_h1 = 'bea7b7acfbad0126b135104024a5f1733e705108f42d59668b05c0c50004c6b0'
vector_multikey_pk = 'z6MkrJVnaZkeFzdQyMZu1cgjg7k1pZZ6pvBQ7XJPt4swbTQ2'
vector_multikey_sk = 'z3u2en7t5LR2WtQH5PfFqMqwVHBeXouLzo6haApm8XHqvjxq'  
vector_m = O.from_hex('bea7b7acfbad0126b135104024a5f1733e705108f42d59668b05c0c50004c6b003f59e5b04ab575b1172cb684f22eede72f0e9033e0b5c67d0e2506768d6ce11')
vector_sg = O.from_hex('20b1a944960b75ca69ba070af4820de6e6acae1afe827d8c566c0f7b932d1bd3abde3222b3095088051439a8b4e7a5356c7ba6d246774f875ebb6ddee1577003')

controls(vector_m1_CanonicalProofOptions ,vector_m2_CanonicalCredential, vector_h1, 
        vector_h2, vector_multikey_pk, vector_multikey_sk, vector_m, vector_sg)

-- vector: B.3 Representation: eddsa-jcs-2022
vector_m2_CanonicalCredential = O.from_str([[{"@context":["https://www.w3.org/ns/credentials/v2","https://www.w3.org/ns/credentials/examples/v2"],"credentialSubject":{"alumniOf":"The School of Examples","id":"did:example:abcdefgh"},"description":"A minimum viable example of an Alumni Credential.","id":"urn:uuid:58172aac-d8ba-11ed-83dd-0b3aef56cc33","issuer":"https://vc.example/issuers/5678","name":"Alumni Credential","type":["VerifiableCredential","AlumniCredential"],"validFrom":"2023-01-01T00:00:00Z"}]])
vector_m1_CanonicalProofOptions = O.from_str([[{"@context":["https://www.w3.org/ns/credentials/v2","https://www.w3.org/ns/credentials/examples/v2"],"created":"2023-02-24T23:36:38Z","cryptosuite":"eddsa-jcs-2022","proofPurpose":"assertionMethod","type":"DataIntegrityProof","verificationMethod":"did:key:z6MkrJVnaZkeFzdQyMZu1cgjg7k1pZZ6pvBQ7XJPt4swbTQ2#z6MkrJVnaZkeFzdQyMZu1cgjg7k1pZZ6pvBQ7XJPt4swbTQ2"}]])
vector_h2 = '59b7cb6251b8991add1ce0bc83107e3db9dbbab5bd2c28f687db1a03abc92f19'
vector_h1 = '66ab154f5c2890a140cb8388a22a160454f80575f6eae09e5a097cabe539a1db'
vector_multikey_pk = 'z6MkrJVnaZkeFzdQyMZu1cgjg7k1pZZ6pvBQ7XJPt4swbTQ2'
vector_multikey_sk = 'z3u2en7t5LR2WtQH5PfFqMqwVHBeXouLzo6haApm8XHqvjxq'  
vector_m = O.from_hex('66ab154f5c2890a140cb8388a22a160454f80575f6eae09e5a097cabe539a1db59b7cb6251b8991add1ce0bc83107e3db9dbbab5bd2c28f687db1a03abc92f19')
vector_sg = O.from_hex('407cd12654b33d718ecbb99179a1506daaa849450bf3fc523cce3e1c96f8b80351da3f253d725c6f00b07c9e5448d50b3ef78012b9ab54255116d069c6dd2808')

controls(vector_m1_CanonicalProofOptions ,vector_m2_CanonicalCredential, vector_h1, 
        vector_h2, vector_multikey_pk, vector_multikey_sk, vector_m, vector_sg)

-- vector: B.4 Representation: Ed25519Signature2020
vector_m2_CanonicalCredential = O.from_str([[<did:example:abcdefgh> <https://www.w3.org/ns/credentials/examples#alumniOf> "The School of Examples" .
<urn:uuid:58172aac-d8ba-11ed-83dd-0b3aef56cc33> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.w3.org/2018/credentials#VerifiableCredential> .
<urn:uuid:58172aac-d8ba-11ed-83dd-0b3aef56cc33> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://www.w3.org/ns/credentials/examples#AlumniCredential> .
<urn:uuid:58172aac-d8ba-11ed-83dd-0b3aef56cc33> <https://schema.org/description> "A minimum viable example of an Alumni Credential." .
<urn:uuid:58172aac-d8ba-11ed-83dd-0b3aef56cc33> <https://schema.org/name> "Alumni Credential" .
<urn:uuid:58172aac-d8ba-11ed-83dd-0b3aef56cc33> <https://www.w3.org/2018/credentials#credentialSubject> <did:example:abcdefgh> .
<urn:uuid:58172aac-d8ba-11ed-83dd-0b3aef56cc33> <https://www.w3.org/2018/credentials#issuer> <https://vc.example/issuers/5678> .
<urn:uuid:58172aac-d8ba-11ed-83dd-0b3aef56cc33> <https://www.w3.org/2018/credentials#validFrom> "2023-01-01T00:00:00Z"^^<http://www.w3.org/2001/XMLSchema#dateTime> .
]])
vector_m1_CanonicalProofOptions = O.from_str([[_:c14n0 <http://purl.org/dc/terms/created> "2023-02-24T23:36:38Z"^^<http://www.w3.org/2001/XMLSchema#dateTime> .
_:c14n0 <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://w3id.org/security#Ed25519Signature2020> .
_:c14n0 <https://w3id.org/security#proofPurpose> <https://w3id.org/security#assertionMethod> .
_:c14n0 <https://w3id.org/security#verificationMethod> <did:key:z6MkrJVnaZkeFzdQyMZu1cgjg7k1pZZ6pvBQ7XJPt4swbTQ2#z6MkrJVnaZkeFzdQyMZu1cgjg7k1pZZ6pvBQ7XJPt4swbTQ2> .
]])
vector_h2 = '517744132ae165a5349155bef0bb0cf2258fff99dfe1dbd914b938d775a36017'
vector_h1 = '04e14bcf5727cba0c0aa04a04d22a56fef915d5f8f7756bb92ae67cb1d0c4847'
vector_multikey_pk = 'z6MkrJVnaZkeFzdQyMZu1cgjg7k1pZZ6pvBQ7XJPt4swbTQ2'
vector_multikey_sk = 'z3u2en7t5LR2WtQH5PfFqMqwVHBeXouLzo6haApm8XHqvjxq'  
vector_m = O.from_hex('04e14bcf5727cba0c0aa04a04d22a56fef915d5f8f7756bb92ae67cb1d0c4847517744132ae165a5349155bef0bb0cf2258fff99dfe1dbd914b938d775a36017')
vector_sg = O.from_hex('cd8d023e8a9b462d563bbbd24c4499d8172738eb3f5235d74f65971e9be36dd7f23a1e201791e9a6747e45b8fa877a984f51f591567365c4d8222ecad39be60c')

controls(vector_m1_CanonicalProofOptions ,vector_m2_CanonicalCredential, vector_h1, 
        vector_h2, vector_multikey_pk, vector_multikey_sk, vector_m, vector_sg)