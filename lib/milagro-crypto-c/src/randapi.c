#include "randapi.h"

/* Initialise a Cryptographically Strong Random Number Generator from
   an octet of raw random data */

void CREATE_CSPRNG(csprng *RNG,octet *RAW)
{
    RAND_seed(RNG,RAW->len,RAW->val);
}

void KILL_CSPRNG(csprng *RNG)
{
    RAND_clean(RNG);
}

