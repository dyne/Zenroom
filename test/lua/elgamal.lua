-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2019-2020 Dyne.org foundation
-- Written by Denis Roio
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

print''
print '= TEST ELGAMAL'
print''
--- small test to see if ElGamal signature works

G = ECP.generator()
O = ECP.order()
salt = ECP.hashtopoint("Constant random string")
message = INT.new(sha256("Message to be authenticated"))
r = INT.random()
commitment = G * r + salt * message

-- keygen
seckey = INT.random()
pubkey = G * seckey

-- sign
k = INT.random()
cipher = { a = G * k,
		   b = pubkey * k + commitment * message }

-- verify
assert(cipher.b - cipher.a * seckey
		  ==
		  commitment * message, "ELGAMAL failure")

print('ELGAMAL SIGNATURE OK')
print''

---------------
-- homomorphism
-- A and B keygen 
A = { sk = INT.random() }
A.pk = G * A.sk
-- pick two random ECP points
m1 = ECP.random()
m2 = ECP.random()
-- calculate operations in clear
ms = m1 + m2
mm = m1 * INT.new(2)
mu = m1 - m2
-- encrypt values
r = INT.random()
M1 = { c1 = G * r }
M1.c2 = A.pk * r + m1
r = INT.random()
M2 = { c1 = G * r }
M2.c2 = A.pk * r + m2
-- check decryption of values
assert(M1.c2 - M1.c1 * A.sk == m1)
assert(M2.c2 - M2.c1 * A.sk == m2)
-- perform homomorphic sum
MS = { C1 = M1.c1 + M2.c1,
	   C2 = M1.c2 + M2.c2 }
assert(MS.C2 - MS.C1 * A.sk == ms)
-- perform homomorphic subtraction
MU = { C1 = M1.c1 - M2.c1,
	   C2 = M1.c2 - M2.c2 }
assert(MU.C2 - MU.C1 * A.sk == mu)
-- perform homomorphic multiplication
MM = { C1 = M1.c1 * INT.new(2),
	   C2 = M1.c2 * INT.new(2) }
assert(MM.C2 - MM.C1 * A.sk == mm)
c = INT.random()
MM = { C1 = M1.c1 * c,
	   C2 = M1.c2 * c }
mm = m1 * c
assert(MM.C2 - MM.C1 * A.sk == mm)

print('ELGAMAL HOMOMORPHISM OK')
print''
