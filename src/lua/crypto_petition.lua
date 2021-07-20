--[[
--This file is part of zenroom
--
--Copyright (C) 2018-2021 Dyne.org foundation
--Coconut implementation by Alberto Sonnino and Denis Roio
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License v3.0
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--Along with this program you should have received a copy of the
--GNU Affero General Public License v3.0
--If not, see http://www.gnu.org/licenses/agpl.txt
--
--Last modified by Denis Roio
--on Tuesday, 20th July 2021
--]]

local petition = { }

local G1 = ECP.generator()
local O  = ECP.order()

function petition.prove_sign_petition(pub, m)
    -- sign == vote
    local k = INT.random()
    -- vote encryption
    local enc_v = { left = G1 * k,
                    right = pub * k + SALT * m }
    -- opposite of vote encryption
    local enc_v_neg = { left = enc_v.left:negative(),
                        right = enc_v.right:negative() + SALT }
    -- commitment to the vote
    local r1 = INT.random()
    local r2 = r1 * (BIG.new(1) - m)
    local cv = G1 * m + SALT * r1
 
    -- proof
    -- create the witnesess
    local wk = INT.random()
    local wm = INT.random()
    local wr1 = INT.random()
    local wr2 = INT.random()
    -- compute the witnessess commitments
    local Aw = G1*wk
    local Bw = pub*wk + SALT*wm
    local Cw = G1*wm + SALT*wr1
    local Dw = cv*wm + SALT*wr2
    -- create the challenge
    local c = ZKP_challenge({enc_v.left, enc_v.right,
                                    cv, Aw, Bw, Cw, Dw}) % O
    -- create responses
    local rk = wk - c * k
    local rm = wm - c * m
    local rr1 = wr1 - c * r1
    local rr2 = wr2 - c * r2
    local pi_vote = { c = c,
                      rk = rk,
                      rm = rm,
                      rr1 = rr1,
                      rr2 = rr2 }
 
    -- signature's Theta
    return { scores = { pos = enc_v,
                        neg = enc_v_neg }, -- left/right tuples
             cv = cv, -- ecp
             pi_vote = pi_vote } -- pi
 end
 
 function petition.verify_sign_petition(pub, theta)
    -- recompute witnessess commitment
    local scores = theta.scores.pos -- only positive, not negative?
    local Aw = G1 * theta.pi_vote.rk
       + scores.left * theta.pi_vote.c
    local Bw = pub * theta.pi_vote.rk
       + SALT * theta.pi_vote.rm
       + scores.right * theta.pi_vote.c
    local Cw = G1 * theta.pi_vote.rm
       + SALT * theta.pi_vote.rr1
       + theta.cv * theta.pi_vote.c
    local Dw = theta.cv * theta.pi_vote.rm
       + SALT * theta.pi_vote.rr2
       + theta.cv * theta.pi_vote.c
    -- verify challenge
    ZEN.assert(theta.pi_vote.c == ZKP_challenge(
                  {scores.left, scores.right,
                   theta.cv, Aw, Bw, Cw, Dw }),
               "verify_sign_petition: challenge fails")
    return true
 end
 
 function petition.prove_tally_petition(sk, scores)
    local wx = INT.random()
    local Aw = { wx:modneg(O) * scores.pos.left,
                 wx:modneg(O) * scores.neg.left  }
    local c = ZKP_challenge(Aw)
    local rx = wx - c * sk
    local dec = { pos = scores.pos.left * sk:modneg(O),
                  neg = scores.neg.left * sk:modneg(O) }
    -- return pi_tally
    return { dec = dec,
             rx = rx,
             c = c    }
 end
 
 function petition.verify_tally_petition(scores, pi_tally)
    local rxneg = pi_tally.rx:modneg(O)
    local Aw = { rxneg*scores.pos.left + pi_tally.c * pi_tally.dec.pos,
                 rxneg*scores.neg.left + pi_tally.c * pi_tally.dec.neg  }
    ZEN.assert(pi_tally.c == ZKP_challenge(Aw),
               "verify_tally_petition: challenge fails")
    return true
 end
 
 function petition.count_signatures_petition(scores, pi_tally)
    local restab = { }
    for idx=1,1000 do
       -- if idx ~= 0 then -- not zero
       restab[(BIG.new(idx) * SALT):octet():hex()] = idx
       -- end
    end
    local res = { pos = scores.pos.right + pi_tally.dec.pos,
                  neg = scores.neg.right + pi_tally.dec.neg  }
    return { pos = restab[res.pos:octet():hex()],
             neg = restab[res.neg:octet():hex()]  }
 end

 return petition