#!/usr/bin/env python

"""
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
"""
import unittest
import json
import mpin_BN254CX

HASH_TYPE_MPIN_ZZZ = mpin_BN254CX.SHA256


class TestMPIN(unittest.TestCase):
    """Tests M-Pin crypto code"""

    def setUp(self):
        pass

    def test_1(self):
        """test_1 Test Vector test"""
        vectors = json.load(open("./MPINTestVectors.json", "r"))
        for vector in vectors:
            print "Test vector {}".format(vector['test_no'])

            PIN1 = vector['PIN1']
            PIN2 = vector['PIN2']
            date = vector['DATE']

            MS1_HEX = vector['MS1']
            MS2_HEX = vector['MS2']

            ms1 = MS1_HEX.decode("hex")
            ms2 = MS2_HEX.decode("hex")

            # Generate server secret shares
            rtn, ss1 = mpin_BN254CX.get_server_secret(ms1)
            self.assertEqual(rtn, 0)
            self.assertEqual(vector['SS1'], ss1.encode("hex"))
            rtn, ss2 = mpin_BN254CX.get_server_secret(ms2)
            self.assertEqual(rtn, 0)
            self.assertEqual(vector['SS2'], ss2.encode("hex"))

            # Combine server secret shares
            rtn, server_secret = mpin_BN254CX.recombine_G2(ss1, ss2)
            self.assertEqual(rtn, 0)
            self.assertEqual(
                vector['SERVER_SECRET'],
                server_secret.encode("hex"))

            mpin_id = vector['MPIN_ID_HEX'].decode("hex")

            # Hash value of MPIN_ID
            hash_mpin_id = mpin_BN254CX.hash_id(HASH_TYPE_MPIN_ZZZ, mpin_id)
            self.assertEqual(
                vector['HASH_MPIN_ID_HEX'],
                hash_mpin_id.encode("hex"))

            # Generate client secret shares
            rtn, cs1 = mpin_BN254CX.get_client_secret(ms1, hash_mpin_id)
            self.assertEqual(rtn, 0)
            self.assertEqual(vector['CS1'], cs1.encode("hex"))
            rtn, cs2 = mpin_BN254CX.get_client_secret(ms2, hash_mpin_id)
            self.assertEqual(rtn, 0)
            self.assertEqual(vector['CS2'], cs2.encode("hex"))

            # Combine client secret shares : TOKEN is the full client secret
            rtn, client_secret = mpin_BN254CX.recombine_G1(cs1, cs2)
            self.assertEqual(rtn, 0)
            self.assertEqual(
                vector['CLIENT_SECRET'],
                client_secret.encode("hex"))

            # Generate Time Permit shares
            rtn, tp1 = mpin_BN254CX.get_client_permit(
                HASH_TYPE_MPIN_ZZZ, date, ms1, hash_mpin_id)
            self.assertEqual(rtn, 0)
            self.assertEqual(vector['TP1'], tp1.encode("hex"))
            rtn, tp2 = mpin_BN254CX.get_client_permit(
                HASH_TYPE_MPIN_ZZZ, date, ms2, hash_mpin_id)
            self.assertEqual(rtn, 0)
            self.assertEqual(vector['TP2'], tp2.encode("hex"))

            # Combine Time Permit shares
            rtn, time_permit = mpin_BN254CX.recombine_G1(tp1, tp2)
            self.assertEqual(rtn, 0)
            self.assertEqual(vector['TIME_PERMIT'], time_permit.encode("hex"))

            # Client extracts PIN from secret to create Token
            rtn, token = mpin_BN254CX.extract_pin(
                HASH_TYPE_MPIN_ZZZ, mpin_id, PIN1, client_secret)
            self.assertEqual(rtn, 0)
            self.assertEqual(vector['TOKEN'], token.encode("hex"))

            x = vector['X'].decode("hex")

            # Client first pass. Use X value from test vectors
            rtn, x, u, ut, sec = mpin_BN254CX.client_1(
                HASH_TYPE_MPIN_ZZZ, date, mpin_id, None, x, PIN2, token, time_permit)
            self.assertEqual(rtn, 0)
            self.assertEqual(vector['X'], x.encode("hex"))
            self.assertEqual(vector['U'], u.encode("hex"))
            self.assertEqual(vector['UT'], ut.encode("hex"))
            self.assertEqual(vector['SEC'], sec.encode("hex"))

            # Server calculates H(ID) and H(T|H(ID))
            HID, HTID = mpin_BN254CX.server_1(
                HASH_TYPE_MPIN_ZZZ, date, mpin_id)

            # Use Y value from test vectors
            y = vector['Y'].decode("hex")

            # Client second pass
            rtn, v = mpin_BN254CX.client_2(x, y, sec)
            self.assertEqual(rtn, 0)
            self.assertEqual(vector['V'], v.encode("hex"))

            # Server second pass
            rtn, E, F = mpin_BN254CX.server_2(
                date, HID, HTID, y, server_secret, u, ut, v, None)
            self.assertEqual(rtn, vector['SERVER_OUTPUT'])


if __name__ == '__main__':
    # Run tests
    unittest.main()
