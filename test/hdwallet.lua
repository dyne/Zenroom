local BTC = require('crypto_bitcoin')
local HDW = require('hdwallet')

local mpk = HDW.parse_extkey('xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8')

local msk = HDW.parse_extkey('xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvNKmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHi')

assert(ZEN.serialize(HDW.neutered(msk)) == ZEN.serialize(mpk))

-- m/0 (hardened)
local m_0sk = HDW.ckd_priv(msk,BIG.new(O.from_hex('80000000')))

local derived = 'xprv9uHRZZhk6KAJC1avXpDAp4MDc3sQKNxDiPvvkX8Br5ngLNv1TxvUxt4cV1rGL5hj6KCesnDYUhd7oWgT11eZG7XnxHrnYeSvkzY7d2bhkJ7'
assert(ZEN.serialize(m_0sk) == ZEN.serialize(HDW.parse_extkey(derived)))
assert(HDW.format_extkey(m_0sk, HDW.MAINSK) == derived)

local derived = 'xpub68Gmy5EdvgibQVfPdqkBBCHxA5htiqg55crXYuXoQRKfDBFA1WEjWgP6LHhwBZeNK1VTsfTFUHCdrfp1bgwQ9xv5ski8PX9rL2dZXvgGDnw'
local m_0pk = HDW.parse_extkey(derived)
assert(ZEN.serialize(HDW.neutered(m_0sk)) == ZEN.serialize(m_0pk))
assert(HDW.format_extkey(m_0sk, HDW.MAINPK) == derived)

local m_0_1sk = HDW.ckd_priv(m_0sk,BIG.new(O.from_hex('01')))
local derived = 'xprv9wTYmMFdV23N2TdNG573QoEsfRrWKQgWeibmLntzniatZvR9BmLnvSxqu53Kw1UmYPxLgboyZQaXwTCg8MSY3H2EU4pWcQDnRnrVA1xe8fs'
assert(ZEN.serialize(m_0_1sk) == ZEN.serialize(HDW.parse_extkey(derived)))
assert(HDW.format_extkey(m_0_1sk, HDW.MAINSK) == derived)

-- derive child public key from parent public key 
local m_0_1pk = HDW.ckd_pub(m_0sk,BIG.new(O.from_hex('01')))
local derived = 'xpub6ASuArnXKPbfEwhqN6e3mwBcDTgzisQN1wXN9BJcM47sSikHjJf3UFHKkNAWbWMiGj7Wf5uMash7SyYq527Hqck2AxYysAA7xmALppuCkwQ'
assert(ZEN.serialize(m_0_1pk) == ZEN.serialize(HDW.parse_extkey(derived)))
assert(HDW.format_extkey(m_0_1pk, HDW.MAINPK) == derived)

-- derive child public key from parent private key 
local save_secret = m_0sk.secret
m_0sk.secret = nil
local m_0_1pk = HDW.ckd_pub(m_0sk,BIG.new(O.from_hex('01')))
m_0sk.secret = save_secret
local derived = 'xpub6ASuArnXKPbfEwhqN6e3mwBcDTgzisQN1wXN9BJcM47sSikHjJf3UFHKkNAWbWMiGj7Wf5uMash7SyYq527Hqck2AxYysAA7xmALppuCkwQ'
I.spy(m_0_1pk)
I.spy(HDW.parse_extkey(derived))
assert(ZEN.serialize(m_0_1pk) == ZEN.serialize(HDW.parse_extkey(derived)))
assert(HDW.format_extkey(m_0_1pk, HDW.MAINPK) == derived)
