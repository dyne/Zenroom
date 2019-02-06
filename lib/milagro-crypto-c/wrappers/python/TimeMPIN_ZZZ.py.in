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

import json
import sys
import timeit
import warnings
import mpin_ZZZ

warnings.filterwarnings("ignore")


def time_func(stmt, n=10, setup='from __main__ import *'):
    t = timeit.Timer(stmt, setup)
    total_time = t.timeit(n)
    iter_time = total_time / n
    iter_per_sec = n / total_time
    print "func:%s nIter:%s total_time:%s iter_time:%s iter_per_sec: %s" % (stmt, n, total_time, iter_time, iter_per_sec)


nIter = 100

HASH_TYPE_MPIN_ZZZ = mpin_ZZZ.SHA256

if __name__ == "__main__":
    # Print hex values
    DEBUG = False

    ONE_PASS = False
    TIME_PERMITS = True
    MPIN_FULL = True
    PIN_ERROR = True

    if TIME_PERMITS:
        date = mpin_ZZZ.today()
    else:
        date = 0

    # Seed
    seedHex = "b75e7857fa17498c333d3c8d42e10f8c3cb8a66f7a84d85f86cd5acb537fa211"
    seed = seedHex.decode("hex")

    # random number generator
    rng = mpin_ZZZ.create_csprng(seed)

    # Identity
    mpin_id = "user@miracl.com"

    # Hash mpin_id
    hash_mpin_id = mpin_ZZZ.hash_id(HASH_TYPE_MPIN_ZZZ, mpin_id)
    if DEBUG:
        print "mpin_id: %s" % mpin_id.encode("hex")
        print "hash_mpin_id: %s" % hash_mpin_id.encode("hex")

    mpin_id = mpin_id

    # Generate master secret for MIRACL and Customer
    time_func('rtn, ms1 = mpin_ZZZ.random_generate(rng)', nIter)
    rtn, ms1 = mpin_ZZZ.random_generate(rng)
    if rtn != 0:
        print "random_generate(rng) Error %s", rtn
    rtn, ms2 = mpin_ZZZ.random_generate(rng)
    if rtn != 0:
        print "random_generate(rng) Error %s", rtn
    if DEBUG:
        print "ms1: %s" % ms1.encode("hex")
        print "ms2: %s" % ms2.encode("hex")

    # Generate server secret shares
    time_func('rtn, ss1 = mpin_ZZZ.get_server_secret(ms1)', nIter)
    rtn, ss1 = mpin_ZZZ.get_server_secret(ms1)
    if rtn != 0:
        print "get_server_secret(ms1) Error %s" % rtn
    rtn, ss2 = mpin_ZZZ.get_server_secret(ms2)
    if rtn != 0:
        print "get_server_secret(ms2) Error %s" % rtn
    if DEBUG:
        print "ss1: %s" % ss1.encode("hex")
        print "ss2: %s" % ss2.encode("hex")

    # Combine server secret shares
    time_func('rtn, server_secret = mpin_ZZZ.recombine_G2(ss1, ss2)', nIter)
    rtn, server_secret = mpin_ZZZ.recombine_G2(ss1, ss2)
    if rtn != 0:
        print "recombine_G2(ss1, ss2) Error %s" % rtn
    if DEBUG:
        print "server_secret: %s" % mpin_ZZZ.server_secret.encode("hex")

    # Generate client secret shares
    time_func('rtn, cs1 = mpin_ZZZ.get_client_secret(ms1, hash_mpin_id)', nIter)
    rtn, cs1 = mpin_ZZZ.get_client_secret(ms1, hash_mpin_id)
    if rtn != 0:
        print "get_client_secret(ms1, hash_mpin_id) Error %s" % rtn
    rtn, cs2 = mpin_ZZZ.get_client_secret(ms2, hash_mpin_id)
    if rtn != 0:
        print "get_client_secret(ms2, hash_mpin_id) Error %s" % rtn
    if DEBUG:
        print "cs1: %s" % cs1.encode("hex")
        print "cs2: %s" % cs2.encode("hex")

    # Combine client secret shares
    time_func('rtn, client_secret = mpin_ZZZ.recombine_G1(cs1, cs2)', nIter)
    rtn, client_secret = mpin_ZZZ.recombine_G1(cs1, cs2)
    if rtn != 0:
        print "recombine_G1(cs1, cs2) Error %s" % rtn
    print "Client Secret: %s" % client_secret.encode("hex")

    # Generate Time Permit shares
    if DEBUG:
        print "Date %s" % date
    time_func(
        'rtn, tp1 = mpin_ZZZ.get_client_permit(HASH_TYPE_MPIN_ZZZ, date, ms1, hash_mpin_id)',
        nIter)
    rtn, tp1 = mpin_ZZZ.get_client_permit(
        HASH_TYPE_MPIN_ZZZ, date, ms1, hash_mpin_id)
    if rtn != 0:
        print "get_client_permit(HASH_TYPE_MPIN_ZZZ, date, ms1, hash_mpin_id) Error %s" % rtn
    rtn, tp2 = mpin_ZZZ.get_client_permit(
        HASH_TYPE_MPIN_ZZZ, date, ms2, hash_mpin_id)
    if rtn != 0:
        print "get_client_permit(HASH_TYPE_MPIN_ZZZ, date, ms2, hash_mpin_id) Error %s" % rtn
    if DEBUG:
        print "tp1: %s" % tp1.encode("hex")
        print "tp2: %s" % tp2.encode("hex")

    # Combine Time Permit shares
    rtn, time_permit = mpin_ZZZ.recombine_G1(tp1, tp2)
    if rtn != 0:
        print "recombine_G1(tp1, tp2) Error %s" % rtn
    if DEBUG:
        print "time_permit: %s" % time_permit.encode("hex")

    # Client extracts PIN from secret to create Token
    PIN = 1234
    time_func(
        'rtn, token = mpin_ZZZ.extract_pin(HASH_TYPE_MPIN_ZZZ, mpin_id, PIN, client_secret)',
        nIter)
    rtn, token = mpin_ZZZ.extract_pin(
        HASH_TYPE_MPIN_ZZZ, mpin_id, PIN, client_secret)
    if rtn != 0:
        print "extract_pin(HASH_TYPE_MPIN_ZZZ, mpin_id, PIN, token) Error %s" % rtn
    print "Token: %s" % token.encode("hex")

    if ONE_PASS:
        print "M-Pin One Pass"
        PIN = 1234
        time_func('epoch_time = mpin_ZZZ.get_time()', nIter)
        epoch_time = mpin_ZZZ.get_time()
        if DEBUG:
            print "epoch_time %s" % epoch_time

        # Client precomputation
        if MPIN_FULL:
            time_func(
                'rtn, pc1, pc2 = mpin_ZZZ.precompute(token, hash_mpin_id)',
                nIter)
            rtn, pc1, pc2 = mpin_ZZZ.precompute(token, hash_mpin_id)

        # Client MPIN
        time_func(
            'rtn, x, u, ut, v, y = mpin_ZZZ.client(HASH_TYPE_MPIN_ZZZ, date, mpin_id, rng, None, PIN, token, time_permit, None, epoch_time)',
            nIter)
        rtn, x, u, ut, v, y = mpin_ZZZ.client(
            HASH_TYPE_MPIN_ZZZ, date, mpin_id, rng, None, PIN, token, time_permit, None, epoch_time)
        if rtn != 0:
            print "MPIN_CLIENT ERROR %s" % rtn

        # Client sends Z=r.ID to Server
        if MPIN_FULL:
            time_func(
                'rtn, r, Z = mpin_ZZZ.get_G1_multiple(rng, 1, None, hash_mpin_id)',
                nIter)
            rtn, r, Z = mpin_ZZZ.get_G1_multiple(rng, 1, None, hash_mpin_id)

        # Server MPIN
        time_func(
            'rtn, HID, HTID, E, F, y2 = mpin_ZZZ.server(HASH_TYPE_MPIN_ZZZ, date, server_secret, u, ut, v, mpin_id, None, epoch_time, None)',
            nIter)
        rtn, HID, HTID, E, F, y2 = mpin_ZZZ.server(
            HASH_TYPE_MPIN_ZZZ, date, server_secret, u, ut, v, mpin_id, None, epoch_time, None)
        if DEBUG:
            print "y2 ", y2.encode("hex")
        if rtn != 0:
            print "ERROR: %s is not authenticated" % mpin_id
            if PIN_ERROR:
                time_func('err = mpin_ZZZ.kangaroo(E, F)', nIter)
                err = mpin_ZZZ.kangaroo(E, F)
                print "Client PIN error %d " % err
            raise SystemExit(0)
        else:
            print "SUCCESS: %s is authenticated" % mpin_id

        if date:
            prHID = HTID
        else:
            prHID = HID
            ut = None

        # Server sends T=w.ID to client
        if MPIN_FULL:
            time_func(
                'rtn, w, T = mpin_ZZZ.get_G1_multiple(rng, 0, None, prHID)',
                nIter)
            rtn, w, T = mpin_ZZZ.get_G1_multiple(rng, 0, None, prHID)
            if rtn != 0:
                print "ERROR: Generating T %s" % rtn

        if MPIN_FULL:
            time_func(
                'HM = mpin_ZZZ.hash_all(HASH_TYPE_MPIN_ZZZ, hash_mpin_id, u, ut, v, y, Z, T)',
                nIter)
            HM = mpin_ZZZ.hash_all(
                HASH_TYPE_MPIN_ZZZ, hash_mpin_id, u, ut, v, y, Z, T)

            time_func(
                'rtn, client_aes_key = mpin_ZZZ.client_key(HASH_TYPE_MPIN_ZZZ, pc1, pc2, PIN, r, x, HM, T)',
                nIter)
            rtn, client_aes_key = mpin_ZZZ.client_key(
                HASH_TYPE_MPIN_ZZZ, pc1, pc2, PIN, r, x, HM, T)
            if rtn != 0:
                print "ERROR: Generating client_aes_key %s" % rtn
            print "Client AES Key: %s" % client_aes_key.encode("hex")

            rtn, server_aes_key = mpin_ZZZ.server_key(
                HASH_TYPE_MPIN_ZZZ, Z, server_secret, w, HM, HID, u, ut)
            if rtn != 0:
                print "ERROR: Generating server_aes_key %s" % rtn
            print "Server AES Key: %s" % server_aes_key.encode("hex")

    else:
        print "M-Pin Three Pass"
        PIN = 1234
        if MPIN_FULL:
            time_func(
                'rtn, pc1, pc2 = mpin_ZZZ.precompute(token, hash_mpin_id)',
                nIter)
            rtn, pc1, pc2 = mpin_ZZZ.precompute(token, hash_mpin_id)
            if rtn != 0:
                print "precompute(token, hash_mpin_id) ERROR %s" % rtn

        # Client first pass
        time_func(
            'rtn, x, u, ut, sec = mpin_ZZZ.client_1(HASH_TYPE_MPIN_ZZZ, date, mpin_id, rng, None, PIN, token, time_permit)',
            nIter)
        rtn, x, u, ut, sec = mpin_ZZZ.client_1(
            HASH_TYPE_MPIN_ZZZ, date, mpin_id, rng, None, PIN, token, time_permit)
        if rtn != 0:
            print "client_1  ERROR %s" % rtn
        if DEBUG:
            print "x: %s" % x.encode("hex")

        # Server calculates H(ID) and H(T|H(ID)) (if time permits enabled),
        # and maps them to points on the curve HID and HTID resp.
        time_func(
            'HID, HTID = mpin_ZZZ.server_1(HASH_TYPE_MPIN_ZZZ, date, mpin_id)',
            nIter)
        HID, HTID = mpin_ZZZ.server_1(HASH_TYPE_MPIN_ZZZ, date, mpin_id)

        # Server generates Random number y and sends it to Client
        time_func('rtn, y = mpin_ZZZ.random_generate(rng)', nIter)
        rtn, y = mpin_ZZZ.random_generate(rng)
        if rtn != 0:
            print "random_generate(rng) Error %s" % rtn

        # Client second pass
        time_func('rtn, v = mpin_ZZZ.client_2(x, y, sec)', nIter)
        rtn, v = mpin_ZZZ.client_2(x, y, sec)
        if rtn != 0:
            print "client_2(x, y, sec) Error %s" % rtn

        # Server second pass
        time_func(
            'rtn, E, F = mpin_ZZZ.server_2(date, HID, HTID, y, server_secret, u, ut, v, None)',
            nIter)
        rtn, E, F = mpin_ZZZ.server_2(
            date, HID, HTID, y, server_secret, u, ut, v, None)
        if rtn != 0:
            print "ERROR: %s is not authenticated" % mpin_id
            if PIN_ERROR:
                time_func('err = mpin_ZZZ.kangaroo(E, F)', nIter)
                err = mpin_ZZZ.kangaroo(E, F)
                print "Client PIN error %d " % err
            raise SystemExit(0)
        else:
            print "SUCCESS: %s is authenticated" % mpin_id

        # Client sends Z=r.ID to Server
        if MPIN_FULL:
            rtn, r, Z = mpin_ZZZ.get_G1_multiple(rng, 1, None, hash_mpin_id)
            if rtn != 0:
                print "ERROR: Generating Z %s" % rtn

        if date:
            prHID = HTID
        else:
            prHID = HID
            ut = None

        # Server sends T=w.ID to client
        if MPIN_FULL:
            time_func(
                'rtn, w, T = mpin_ZZZ.get_G1_multiple(rng, 0, None, prHID)',
                nIter)
            rtn, w, T = mpin_ZZZ.get_G1_multiple(rng, 0, None, prHID)
            if rtn != 0:
                print "ERROR: Generating T %s" % rtn

            time_func(
                'HM = mpin_ZZZ.hash_all(HASH_TYPE_MPIN_ZZZ, hash_mpin_id, u, ut, v, y, Z, T)',
                nIter)
            HM = mpin_ZZZ.hash_all(
                HASH_TYPE_MPIN_ZZZ, hash_mpin_id, u, ut, v, y, Z, T)

            time_func(
                'rtn, client_aes_key = mpin_ZZZ.client_key(HASH_TYPE_MPIN_ZZZ, pc1, pc2, PIN, r, x, HM, T)',
                nIter)
            rtn, client_aes_key = mpin_ZZZ.client_key(
                HASH_TYPE_MPIN_ZZZ, pc1, pc2, PIN, r, x, HM, T)
            if rtn != 0:
                print "ERROR: Generating client_aes_key %s" % rtn
            print "Client AES Key: %s" % client_aes_key.encode("hex")

            time_func(
                'rtn, server_aes_key = mpin_ZZZ.server_key(HASH_TYPE_MPIN_ZZZ, Z, server_secret, w, HM, HID, u, ut)',
                nIter)
            rtn, server_aes_key = mpin_ZZZ.server_key(
                HASH_TYPE_MPIN_ZZZ, Z, server_secret, w, HM, HID, u, ut)
            if rtn != 0:
                print "ERROR: Generating server_aes_key %s" % rtn
            print "Server AES Key: %s" % server_aes_key.encode("hex")

    if MPIN_FULL:
        plaintext = "A test message"
        print "message to encrypt: ", plaintext
        header_hex = "1554a69ecbf04e507eb6985a234613246206c85f8af73e61ab6e2382a26f457d"
        header = header_hex.decode("hex")
        iv_hex = "2b213af6b0edf6972bf996fb"
        iv = iv_hex.decode("hex")
        time_func(
            'ciphertext, tag = mpin_ZZZ.aes_gcm_encrypt(client_aes_key, iv, header, plaintext)',
            nIter)
        ciphertext, tag = mpin_ZZZ.aes_gcm_encrypt(
            client_aes_key, iv, header, plaintext)
        print "ciphertext ", ciphertext.encode("hex")
        print "tag1 ", tag.encode("hex")

        time_func(
            'plaintext2, tag2 = mpin_ZZZ.aes_gcm_decrypt(server_aes_key, iv, header, ciphertext)',
            nIter)
        plaintext2, tag2 = mpin_ZZZ.aes_gcm_decrypt(
            server_aes_key, iv, header, ciphertext)
        print "decrypted message: ", plaintext2
        print "tag2 ", tag2.encode("hex")
