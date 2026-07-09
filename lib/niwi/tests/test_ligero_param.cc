/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 */

#include "ec/p256k1.h"
#include "ligero/ligero_param.h"

#include <cassert>
#include <cstdio>

int main(void) {
    using Field = proofs::Fp256k1Base;

    proofs::LigeroParam<Field> p(
        5,  /* witness elements */
        0,  /* quadratic constraints */
        4,  /* inverse code rate */
        1,  /* opened columns */
        16  /* precomputed encoded block size */);

    assert(p.nw == 5);
    assert(p.nq == 0);
    assert(p.rateinv == 4);
    assert(p.nreq == 1);
    assert(p.block_enc == 16);
    assert(p.block == 2);
    assert(p.dblock == 3);
    assert(p.block_ext == 13);
    assert(p.r == 1);
    assert(p.w == 1);
    assert(p.nwrow == 5);
    assert(p.nrow >= p.nwrow + 3);
    assert(p.mc_pathlen != 0);

    proofs::LigeroProof<Field> proof(&p);
    assert(proof.y_ldt.size() == p.block);
    assert(proof.y_dot.size() == p.dblock);
    assert(proof.y_quad_0.size() == p.r);
    assert(proof.req.size() == p.nrow * p.nreq);

    std::printf("lib/niwi Ligero parameter boundary test passed.\n");
    return 0;
}
