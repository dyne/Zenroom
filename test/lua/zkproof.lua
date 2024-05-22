-- zkmac
-- Ref: Buchanan, William J (2024). Elliptic curve based zero knowledge proofs with Python. Asecuritysite.com. https://asecuritysite.com/zero/zkhmac

-- Chatzigiannakis, I., Pyrgelis, A., Spirakis, P. G., & Stamatiou, Y. C. (2011, October). Elliptic curve based zero knowledge proofs and their applicability on resource constrained devices. In 2011 IEEE eighth international conference on mobile ad-hoc and sensor systems (pp. 715–720). IEEE.


function zk_make(secret, hash, salt)
    local hh = hash or HASH.new('sha256')
    local st = salt or O.zero(32)
    local res = { zksec = BIG.new(
                      hh:process(secret .. st))
                      % ECP.order() }
    res.zkpub = res.zksec * ECP.generator()
    return res
end

function zk_prove(challenge, zksec, hash, salt)
    local hh = hash or HASH.new('sha256')
    local st = salt or O.zero(32)
    local r = BIG.modrand(ECP.order())
    local rG1 = ECP.generator() * r
    local c = hh:process(challenge..rG1:octet()..st)
    local m = r + c * zksec
    return {c=c,m=m}
end

function zk_verify(challenge, proof, zkpub, hash, salt)
    local hh = hash or HASH.new('sha256')
    local st = salt or O.zero(32)
    local mG1 = ECP.generator() * proof.m
    local cG1 = zkpub * (BIG.new(proof.c) % ECP.order())
    local hpk = hh:process(challenge.. (mG1 - cG1):octet()..st)
    return(hpk == proof.c)
end

hash = HASH.new('sha256')

-- prepare a secret to be proven via zk
secret = zk_make(O.from_string('the answer is 42'))

I.print(secret) -- also provides public hash of secret

challenge = O.from_string('prove you know it')

proof = zk_prove(challenge, secret['zksec'])

I.print({challenge=challenge,proof=proof})

assert(zk_verify(challenge, proof, secret['zkpub'], hash))
