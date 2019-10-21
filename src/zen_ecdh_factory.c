/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2019 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 */

#include <jutils.h>
#include <zen_ecdh.h>
#include <zen_error.h>

#include <ecdh_ED25519.h>
#include <ecdh_BLS383.h>
#include <ecdh_GOLDILOCKS.h>
#include <ecdh_SECP256K1.h>

ecdh *ecdh_new_curve(lua_State *L, const char *cname) {
	ecdh *e = NULL;
	char curve[16];
	if(cname) {
               strncpy(curve,cname,15);
        } else {
               strncpy(curve,"ed25519",15);
        }

	HEREs(curve);
	if(strcasecmp(curve,"ec25519")   ==0
	   || strcasecmp(curve,"ed25519")==0
	   || strcasecmp(curve,"25519")  ==0) {
		e = (ecdh*)lua_newuserdata(L, sizeof(ecdh));
		e->keysize = EGS_ED25519; // public key size
		e->fieldsize = EFS_ED25519;
		e->rng = NULL;
		e->hash = HASH_TYPE_ED25519;
		e->ECP__KEY_PAIR_GENERATE = ECP_ED25519_KEY_PAIR_GENERATE;
		e->ECP__PUBLIC_KEY_VALIDATE	= ECP_ED25519_PUBLIC_KEY_VALIDATE;
		e->ECP__SVDP_DH = ECP_ED25519_SVDP_DH;
		e->ECP__ECIES_ENCRYPT = ECP_ED25519_ECIES_ENCRYPT;
		e->ECP__ECIES_DECRYPT = ECP_ED25519_ECIES_DECRYPT;
		e->ECP__SP_DSA = ECP_ED25519_SP_DSA;
		e->ECP__VP_DSA = ECP_ED25519_VP_DSA;

	} else if(strcasecmp(curve,"bls383")==0) {
			e = (ecdh*)lua_newuserdata(L, sizeof(ecdh));
			e->keysize = EGS_BLS383;
			e->fieldsize = EFS_BLS383;
			e->rng = NULL;
			e->hash = HASH_TYPE_BLS383;
			e->ECP__KEY_PAIR_GENERATE = ECP_BLS383_KEY_PAIR_GENERATE;
			e->ECP__PUBLIC_KEY_VALIDATE	= ECP_BLS383_PUBLIC_KEY_VALIDATE;
			e->ECP__SVDP_DH = ECP_BLS383_SVDP_DH;
			e->ECP__ECIES_ENCRYPT = ECP_BLS383_ECIES_ENCRYPT;
			e->ECP__ECIES_DECRYPT = ECP_BLS383_ECIES_DECRYPT;
			e->ECP__SP_DSA = ECP_BLS383_SP_DSA;
			e->ECP__VP_DSA = ECP_BLS383_VP_DSA;

	} else if(strcasecmp(curve,"goldilocks")==0) {
		e = (ecdh*)lua_newuserdata(L, sizeof(ecdh));
		e->keysize = EGS_GOLDILOCKS;
		e->fieldsize = EFS_GOLDILOCKS;
		e->rng = NULL;
		e->hash = HASH_TYPE_GOLDILOCKS;
		e->ECP__KEY_PAIR_GENERATE = ECP_GOLDILOCKS_KEY_PAIR_GENERATE;
		e->ECP__PUBLIC_KEY_VALIDATE	= ECP_GOLDILOCKS_PUBLIC_KEY_VALIDATE;
		e->ECP__SVDP_DH = ECP_GOLDILOCKS_SVDP_DH;
		e->ECP__ECIES_ENCRYPT = ECP_GOLDILOCKS_ECIES_ENCRYPT;
		e->ECP__ECIES_DECRYPT = ECP_GOLDILOCKS_ECIES_DECRYPT;
		e->ECP__SP_DSA = ECP_GOLDILOCKS_SP_DSA;
		e->ECP__VP_DSA = ECP_GOLDILOCKS_VP_DSA;

	} else if(strcasecmp(curve,"secp256k1")==0) {
		e = (ecdh*)lua_newuserdata(L, sizeof(ecdh));
		e->keysize = EGS_SECP256K1*2;
		e->fieldsize = EFS_SECP256K1;
		e->rng = NULL;
		e->hash = HASH_TYPE_SECP256K1;
		e->ECP__KEY_PAIR_GENERATE = ECP_SECP256K1_KEY_PAIR_GENERATE;
		e->ECP__PUBLIC_KEY_VALIDATE	= ECP_SECP256K1_PUBLIC_KEY_VALIDATE;
		e->ECP__SVDP_DH = ECP_SECP256K1_SVDP_DH;
		e->ECP__ECIES_ENCRYPT = ECP_SECP256K1_ECIES_ENCRYPT;
		e->ECP__ECIES_DECRYPT = ECP_SECP256K1_ECIES_DECRYPT;
		e->ECP__SP_DSA = ECP_SECP256K1_SP_DSA;
		e->ECP__VP_DSA = ECP_SECP256K1_VP_DSA;

       } else {
               error(L, "%s: curve not found: %s",__func__,curve);
               return NULL;
       }
	strncpy(e->curve,curve,15);
// TODO: where is this set?
// TODO: this is missing for the other curves...
#if CURVETYPE_ED25519==MONTGOMERY
	strcpy(e->type,"montgomery");
#elif CURVETYPE_ED25519==WEIERSTRASS
	strcpy(e->type,"weierstrass");
#elif CURVETYPE_ED25519==EDWARDS
	strcpy(e->type,"edwards");
#else
	strcpy(e->type,"unknown");
#endif
	func(NULL,"ECDH new curve %s",e->curve);
	func(NULL,"ECDH type %s",e->type);
	func(NULL,"ECDH keysize[%u] fieldsize[%u]",e->keysize,e->fieldsize);
	return e;
}
