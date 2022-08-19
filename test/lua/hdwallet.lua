local BTC = require('crypto_bitcoin')
local HDW = require('hdwallet')

--local mskgenerated = HDW.master_key_generation(O.from_hex('000102030405060708090a0b0c0d0e0f'))

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

assert(ZEN.serialize(m_0_1pk) == ZEN.serialize(HDW.parse_extkey(derived)))
assert(HDW.format_extkey(m_0_1pk, HDW.MAINPK) == derived)

-- m/0H/1/2H
local m_0_1_2sk = HDW.ckd_priv(m_0_1sk,BIG.new(O.from_hex('80000002')))
local derived = 'xprv9z4pot5VBttmtdRTWfWQmoH1taj2axGVzFqSb8C9xaxKymcFzXBDptWmT7FwuEzG3ryjH4ktypQSAewRiNMjANTtpgP4mLTj34bhnZX7UiM'
assert(ZEN.serialize(m_0_1_2sk) == ZEN.serialize(HDW.parse_extkey(derived)))
assert(HDW.format_extkey(m_0_1_2sk, HDW.MAINSK) == derived)

local m_0_1_2pk = HDW.neutered(m_0_1_2sk)
local derived = 'xpub6D4BDPcP2GT577Vvch3R8wDkScZWzQzMMUm3PWbmWvVJrZwQY4VUNgqFJPMM3No2dFDFGTsxxpG5uJh7n7epu4trkrX7x7DogT5Uv6fcLW5'
assert(ZEN.serialize(m_0_1_2pk) == ZEN.serialize(HDW.parse_extkey(derived)))
assert(HDW.format_extkey(m_0_1_2pk, HDW.MAINPK) == derived)

-- m/0H/1/2H/2
local m_0_1_2_2sk = HDW.ckd_priv(m_0_1_2sk,BIG.new(O.from_hex('02')))
local derived = 'xprvA2JDeKCSNNZky6uBCviVfJSKyQ1mDYahRjijr5idH2WwLsEd4Hsb2Tyh8RfQMuPh7f7RtyzTtdrbdqqsunu5Mm3wDvUAKRHSC34sJ7in334'
assert(ZEN.serialize(m_0_1_2_2sk) == ZEN.serialize(HDW.parse_extkey(derived)))
assert(HDW.format_extkey(m_0_1_2_2sk, HDW.MAINSK) == derived)

local m_0_1_2_2pk = HDW.ckd_pub(m_0_1_2sk,BIG.new(O.from_hex('02')))
local derived = 'xpub6FHa3pjLCk84BayeJxFW2SP4XRrFd1JYnxeLeU8EqN3vDfZmbqBqaGJAyiLjTAwm6ZLRQUMv1ZACTj37sR62cfN7fe5JnJ7dh8zL4fiyLHV'
assert(ZEN.serialize(m_0_1_2_2pk) == ZEN.serialize(HDW.parse_extkey(derived)))
assert(HDW.format_extkey(m_0_1_2_2pk, HDW.MAINPK) == derived)

local m_0_1_2_2pk = HDW.ckd_pub(m_0_1_2pk,BIG.new(O.from_hex('02')))
local derived = 'xpub6FHa3pjLCk84BayeJxFW2SP4XRrFd1JYnxeLeU8EqN3vDfZmbqBqaGJAyiLjTAwm6ZLRQUMv1ZACTj37sR62cfN7fe5JnJ7dh8zL4fiyLHV'
assert(ZEN.serialize(m_0_1_2_2pk) == ZEN.serialize(HDW.parse_extkey(derived)))
assert(HDW.format_extkey(m_0_1_2_2pk, HDW.MAINPK) == derived)


-- m/0H/1/2H/2/1000000000
local m_0_1_2_2_xsk = HDW.ckd_priv(m_0_1_2_2sk,BIG.from_decimal('1000000000'))
local derived = 'xprvA41z7zogVVwxVSgdKUHDy1SKmdb533PjDz7J6N6mV6uS3ze1ai8FHa8kmHScGpWmj4WggLyQjgPie1rFSruoUihUZREPSL39UNdE3BBDu76'
assert(ZEN.serialize(m_0_1_2_2_xsk) == ZEN.serialize(HDW.parse_extkey(derived)))
assert(HDW.format_extkey(m_0_1_2_2_xsk, HDW.MAINSK) == derived)

local m_0_1_2_2_xpk = HDW.ckd_pub(m_0_1_2_2sk,BIG.from_decimal('1000000000'))
local derived = 'xpub6H1LXWLaKsWFhvm6RVpEL9P4KfRZSW7abD2ttkWP3SSQvnyA8FSVqNTEcYFgJS2UaFcxupHiYkro49S8yGasTvXEYBVPamhGW6cFJodrTHy'
assert(ZEN.serialize(m_0_1_2_2_xpk) == ZEN.serialize(HDW.parse_extkey(derived)))
assert(HDW.format_extkey(m_0_1_2_2_xpk, HDW.MAINPK) == derived)


-- default wallet support example
local mnemonic = "void come effort suffer camp survey warrior heavy shoot primary clutch crush open amazing screen patrol group space point ten exist slush involve unfold"
local password = "password"

local parent_key = HDW.mnemonic_master_key(mnemonic, password)
I.spy(parent_key)
local c00 = HDW.standard_child(parent_key, INT.new(42))
local c01 = HDW.standard_child(parent_key, INT.new(1729))
I.spy(c00)
I.spy(c01)

local c10 = HDW.standard_child(parent_key, INT.new(42), '', false)
local c11 = HDW.standard_child(parent_key, INT.new(1729), '', false)

assert(ZEN.serialize(c00) == ZEN.serialize(c10))
assert(ZEN.serialize(c01) == ZEN.serialize(c11))
