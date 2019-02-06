#ifndef CONFIG_CURVE_ZZZ_H
#define CONFIG_CURVE_ZZZ_H

#include"amcl.h"
#include"config_field_YYY.h"

// ECP stuff

#define CURVETYPE_ZZZ @CT@
#define PAIRING_FRIENDLY_ZZZ @PF@
#define CURVE_SECURITY_ZZZ @CS@


#if PAIRING_FRIENDLY_ZZZ != NOT
//#define USE_GLV_ZZZ	  /**< Note this method is patented (GLV), so maybe you want to comment this out */
//#define USE_GS_G2_ZZZ /**< Well we didn't patent it :) But may be covered by GLV patent :( */
#define USE_GS_GT_ZZZ /**< Not patented, so probably safe to always use this */

#define POSITIVEX 0
#define NEGATIVEX 1

#define SEXTIC_TWIST_ZZZ @ST@
#define SIGN_OF_X_ZZZ @SX@

#endif

#if CURVE_SECURITY_ZZZ == 128
#define AESKEY_ZZZ 16 /**< Symmetric Key size - 128 bits */
#define HASH_TYPE_ZZZ SHA256  /**< Hash type */
#endif

#if CURVE_SECURITY_ZZZ == 192
#define AESKEY_ZZZ 24 /**< Symmetric Key size - 192 bits */
#define HASH_TYPE_ZZZ SHA384  /**< Hash type */
#endif

#if CURVE_SECURITY_ZZZ == 256
#define AESKEY_ZZZ 32 /**< Symmetric Key size - 256 bits */
#define HASH_TYPE_ZZZ SHA512  /**< Hash type */
#endif



#endif
