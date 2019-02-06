# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

cmake_minimum_required(VERSION 3.1)

# This file defines the parameters for the various curves and RSA
# levels supported by AMCL.
#
# The parameters can be accessed individually by name using the
# `amcl_curve_field(<field> <curve>)` and `amcl_rsa_field(<field>
# <level>)` functions in this file.
#
# The parameters can be loaded into the variables using the
# `amcl_load_curve(<curve>)` and `amcl_load_rsa(<level>)` macros in
# this file.
#
# The sister module `AMCLExpand.cmake` contains helper functions to
# expand template sources with the parameters defined here.

#######################################
# AMCL Curve parameters
#######################################
set(AMCL_CURVE_FIELDS        TB  TF         TC         NB  BASE NBT M8 MT                   CT          PF  ST     SX        CS )
set(AMCL_CURVE_64_ED25519    256 25519      ED25519    32  56   255 5  PSEUDO_MERSENNE      EDWARDS     NOT .      .         128)
set(AMCL_CURVE_64_C25519     256 25519      C25519     32  56   255 5  PSEUDO_MERSENNE      MONTGOMERY  NOT .      .         128)
set(AMCL_CURVE_64_NIST256    256 NIST256    NIST256    32  56   256 7  NOT_SPECIAL          WEIERSTRASS NOT .      .         128)
set(AMCL_CURVE_64_BRAINPOOL  256 BRAINPOOL  BRAINPOOL  32  56   256 7  NOT_SPECIAL          WEIERSTRASS NOT .      .         128)
set(AMCL_CURVE_64_ANSSI      256 ANSSI      ANSSI      32  56   256 7  NOT_SPECIAL          WEIERSTRASS NOT .      .         128)
set(AMCL_CURVE_64_HIFIVE     336 HIFIVE     HIFIVE     42  60   336 5  PSEUDO_MERSENNE      EDWARDS     NOT .      .         128)
set(AMCL_CURVE_64_GOLDILOCKS 448 GOLDILOCKS GOLDILOCKS 56  58   448 7  GENERALISED_MERSENNE EDWARDS     NOT .      .         128)
set(AMCL_CURVE_64_NIST384    384 NIST384    NIST384    48  56   384 7  NOT_SPECIAL          WEIERSTRASS NOT .      .         128)
set(AMCL_CURVE_64_C41417     416 C41417     C41417     52  60   414 7  PSEUDO_MERSENNE      EDWARDS     NOT .      .         128)
set(AMCL_CURVE_64_NIST521    528 NIST521    NIST521    66  60   521 7  PSEUDO_MERSENNE      WEIERSTRASS NOT .      .         128)
set(AMCL_CURVE_64_NUMS256W   256 256PMW     NUMS256W   32  56   256 3  PSEUDO_MERSENNE      WEIERSTRASS NOT .      .         128)
set(AMCL_CURVE_64_NUMS256E   256 256PME     NUMS256E   32  56   256 3  PSEUDO_MERSENNE      EDWARDS     NOT .      .         128)
set(AMCL_CURVE_64_NUMS384W   384 384PM      NUMS384W   48  56   384 3  PSEUDO_MERSENNE      WEIERSTRASS NOT .      .         128)
set(AMCL_CURVE_64_NUMS384E   384 384PM      NUMS384E   48  56   384 3  PSEUDO_MERSENNE      EDWARDS     NOT .      .         128)
set(AMCL_CURVE_64_NUMS512W   512 512PM      NUMS512W   64  56   512 7  PSEUDO_MERSENNE      WEIERSTRASS NOT .      .         128)
set(AMCL_CURVE_64_NUMS512E   512 512PM      NUMS512E   64  56   512 7  PSEUDO_MERSENNE      EDWARDS     NOT .      .         128)
set(AMCL_CURVE_64_SECP256K1  256 SECP256K1  SECP256K1  32  56   256 7  NOT_SPECIAL          WEIERSTRASS NOT .      .         128)
set(AMCL_CURVE_64_BN254      256 BN254      BN254      32  56   254 3  NOT_SPECIAL          WEIERSTRASS BN  D_TYPE NEGATIVEX 128)
set(AMCL_CURVE_64_BN254CX    256 BN254CX    BN254CX    32  56   254 3  NOT_SPECIAL          WEIERSTRASS BN  D_TYPE NEGATIVEX 128)
set(AMCL_CURVE_64_BLS381     384 BLS381     BLS381     48  58   381 3  NOT_SPECIAL          WEIERSTRASS BLS M_TYPE NEGATIVEX 128)
set(AMCL_CURVE_64_BLS383     384 BLS383     BLS383     48  58   383 3  NOT_SPECIAL          WEIERSTRASS BLS M_TYPE POSITIVEX 128)
set(AMCL_CURVE_64_BLS24      480 BLS24      BLS24      60  56   479 3  NOT_SPECIAL          WEIERSTRASS BLS M_TYPE POSITIVEX 192)
set(AMCL_CURVE_64_BLS48      560 BLS48      BLS48      70  58   556 3  NOT_SPECIAL          WEIERSTRASS BLS M_TYPE POSITIVEX 256)
set(AMCL_CURVE_64_FP256BN    256 FP256BN    FP256BN    32  56   256 3  NOT_SPECIAL          WEIERSTRASS BN  M_TYPE NEGATIVEX 128)
set(AMCL_CURVE_64_FP512BN    512 FP512BN    FP512BN    64  60   512 3  NOT_SPECIAL          WEIERSTRASS BN  M_TYPE POSITIVEX 128)
set(AMCL_CURVE_64_BLS461     464 BLS461     BLS461     58  60   461 3  NOT_SPECIAL          WEIERSTRASS BLS M_TYPE NEGATIVEX 128)
#  (                         TB  TF         TC         NB  BASE NBT M8 MT                   CT          PF  ST     SX        CS )
set(AMCL_CURVE_32_ED25519    256 25519      ED25519    32  29   255 5  PSEUDO_MERSENNE      EDWARDS     NOT .      .         128)
set(AMCL_CURVE_32_C25519     256 25519      C25519     32  29   255 5  PSEUDO_MERSENNE      MONTGOMERY  NOT .      .         128)
set(AMCL_CURVE_32_NIST256    256 NIST256    NIST256    32  28   256 7  NOT_SPECIAL          WEIERSTRASS NOT .      .         128)
set(AMCL_CURVE_32_BRAINPOOL  256 BRAINPOOL  BRAINPOOL  32  28   256 7  NOT_SPECIAL          WEIERSTRASS NOT .      .         128)
set(AMCL_CURVE_32_ANSSI      256 ANSSI      ANSSI      32  28   256 7  NOT_SPECIAL          WEIERSTRASS NOT .      .         128)
set(AMCL_CURVE_32_HIFIVE     336 HIFIVE     HIFIVE     42  29   336 5  PSEUDO_MERSENNE      EDWARDS     NOT .      .         128)
set(AMCL_CURVE_32_GOLDILOCKS 448 GOLDILOCKS GOLDILOCKS 56  29   448 7  GENERALISED_MERSENNE EDWARDS     NOT .      .         128)
set(AMCL_CURVE_32_NIST384    384 NIST384    NIST384    48  29   384 7  NOT_SPECIAL          WEIERSTRASS NOT .      .         128)
set(AMCL_CURVE_32_C41417     416 C41417     C41417     52  29   414 7  PSEUDO_MERSENNE      EDWARDS     NOT .      .         128)
set(AMCL_CURVE_32_NIST521    528 NIST521    NIST521    66  28   521 7  PSEUDO_MERSENNE      WEIERSTRASS NOT .      .         128)
set(AMCL_CURVE_32_NUMS256W   256 256PMW     NUMS256W   32  28   256 3  PSEUDO_MERSENNE      WEIERSTRASS NOT .      .         128)
set(AMCL_CURVE_32_NUMS256E   256 256PME     NUMS256E   32  29   256 3  PSEUDO_MERSENNE      EDWARDS     NOT .      .         128)
set(AMCL_CURVE_32_NUMS384W   384 384PM      NUMS384W   48  29   384 3  PSEUDO_MERSENNE      WEIERSTRASS NOT .      .         128)
set(AMCL_CURVE_32_NUMS384E   384 384PM      NUMS384E   48  29   384 3  PSEUDO_MERSENNE      EDWARDS     NOT .      .         128)
set(AMCL_CURVE_32_NUMS512W   512 512PM      NUMS512W   64  29   512 7  PSEUDO_MERSENNE      WEIERSTRASS NOT .      .         128)
set(AMCL_CURVE_32_NUMS512E   512 512PM      NUMS512E   64  29   512 7  PSEUDO_MERSENNE      EDWARDS     NOT .      .         128)
set(AMCL_CURVE_32_SECP256K1  256 SECP256K1  SECP256K1  32  28   256 7  NOT_SPECIAL          WEIERSTRASS NOT .      .         128)
set(AMCL_CURVE_32_BN254      256 BN254      BN254      32  28   254 3  NOT_SPECIAL          WEIERSTRASS BN  D_TYPE NEGATIVEX 128)
set(AMCL_CURVE_32_BN254CX    256 BN254CX    BN254CX    32  28   254 3  NOT_SPECIAL          WEIERSTRASS BN  D_TYPE NEGATIVEX 128)
set(AMCL_CURVE_32_BLS381     384 BLS381     BLS381     48  29   381 3  NOT_SPECIAL          WEIERSTRASS BLS M_TYPE NEGATIVEX 128)
set(AMCL_CURVE_32_BLS383     384 BLS383     BLS383     48  29   383 3  NOT_SPECIAL          WEIERSTRASS BLS M_TYPE POSITIVEX 128)
set(AMCL_CURVE_32_BLS24      480 BLS24      BLS24      60  29   479 3  NOT_SPECIAL          WEIERSTRASS BLS M_TYPE POSITIVEX 192)
set(AMCL_CURVE_32_BLS48      560 BLS48      BLS48      70  29   556 3  NOT_SPECIAL          WEIERSTRASS BLS M_TYPE POSITIVEX 256)
set(AMCL_CURVE_32_FP256BN    256 FP256BN    FP256BN    32  28   256 3  NOT_SPECIAL          WEIERSTRASS BN  M_TYPE NEGATIVEX 128)
set(AMCL_CURVE_32_FP512BN    512 FP512BN    FP512BN    64  29   512 3  NOT_SPECIAL          WEIERSTRASS BN  M_TYPE POSITIVEX 128)
set(AMCL_CURVE_32_BLS461     464 BLS461     BLS461     58  28   461 3  NOT_SPECIAL          WEIERSTRASS BLS M_TYPE NEGATIVEX 128)
#  (                         TB  TF         TC         NB  BASE NBT M8 MT                   CT          PF  ST     SX        CS )
set(AMCL_CURVE_16_ED25519    256 25519      ED25519    32  13   255 5  PSEUDO_MERSENNE      EDWARDS     NOT .      .         128)
set(AMCL_CURVE_16_NUMS256E   256 256PME     NUMS256E   32  13   256 3  PSEUDO_MERSENNE      EDWARDS     NOT .      .         128)
set(AMCL_CURVE_16_BN254      256 BN254      BN254      32  13   254 3  NOT_SPECIAL          WEIERSTRASS BN  D_TYPE NEGATIVEX 128)
set(AMCL_CURVE_16_BN254CX    256 BN254CX    BN254CX    32  13   254 3  NOT_SPECIAL          WEIERSTRASS BN  D_TYPE NEGATIVEX 128)

#######################################
# AMCL RSA parameters
#######################################
set(AMCL_RSA_FIELDS          TB   TFF  NB  BASE ML)
set(AMCL_RSA_64_2048         1024 2048 128 58   2 )
set(AMCL_RSA_64_3072         384  3072 48  56   8 )
set(AMCL_RSA_64_4096         512  4096 64  60   8 )
#  (                         TB   TFF  NB  BASE ML)
set(AMCL_RSA_32_2048         1024 2048 128 28   2 )
set(AMCL_RSA_32_3072         384  3072 48  28   8 )
set(AMCL_RSA_32_4096         512  4096 64  29   8 )
#  (                         TB   TFF  NB  BASE ML)
set(AMCL_RSA_16_2048         256  2048 32  13   8 )

########################################
# Get supported curves and RSA levels
########################################
function(amcl_supported_curves output word_size)
  get_cmake_property(_allvars VARIABLES)
  string(REGEX MATCHALL "AMCL_CURVE_${word_size}_[a-zA-Z0-9]*" _amcl_curve_vars "${_allvars}")
  string(REGEX REPLACE "AMCL_CURVE_[0-9][0-9]_" "" _names "${_amcl_curve_vars}")
  list(REMOVE_DUPLICATES _names)
  set("${output}" "${_names}" PARENT_SCOPE)
endfunction()

function(amcl_supported_rsa_levels output word_size)
  get_cmake_property(_allvars VARIABLES)
  string(REGEX MATCHALL "AMCL_RSA_${word_size}_[0-9]*" _amcl_rsa_vars "${_allvars}")
  string(REGEX REPLACE "AMCL_RSA_[0-9][0-9]_" "" _names "${_amcl_rsa_vars}")
  list(REMOVE_DUPLICATES _names)
  set("${output}" "${_names}" PARENT_SCOPE)
endfunction()

#######################################
# AMCL parameters accessors
#######################################

# Loads the parameters for <curve> into variables in the calling
# scope.
macro(amcl_load_curve curve)
  if(NOT AMCL_CURVE_${WORD_SIZE}_${curve})
    message(FATAL_ERROR "Invalid curve: ${curve} for word size ${WORD_SIZE}")
  endif()

  # Export all predefined fields
  foreach(field ${AMCL_CURVE_FIELDS})
    list(FIND AMCL_CURVE_FIELDS "${field}" index)
    list(GET  AMCL_CURVE_${WORD_SIZE}_${curve} ${index} ${field})
  endforeach()

  # Export computed fields
  # - BD
  set(BD "${TB}_${BASE}")

  # - SH
  math(EXPR SH "${BASE} * (1 + ((8 * ${NB} - 1) / ${BASE})) - ${NBT}")
  if (SH GREATER "30")
    set(SH "30")
  endif()
endmacro()

# Loads the parameters for RSA <level> into variables in the calling
# scope.
macro(amcl_load_rsa level)
  if(NOT AMCL_RSA_${WORD_SIZE}_${level})
    message(FATAL_ERROR "Invalid RSA level: ${level} for word size ${WORD_SIZE}")
  endif()

  # Export all predefined fields
  foreach(field ${AMCL_RSA_FIELDS})
    list(FIND AMCL_RSA_FIELDS "${field}" index)
    list(GET  AMCL_RSA_${WORD_SIZE}_${level} ${index} ${field})
  endforeach()

  # Export computed fields
  # - BD
  set(BD "${TB}_${BASE}")

endmacro()

# Retrieves the value of <field> for <curve>.
#
# If the optional `DEST <name>` argument is supplied, the value is
# saved to <name> in the calling scope. Otherwise, it is saved to
# <field> in the calling scope.
function(amcl_curve_field field curve)
  cmake_parse_arguments(amcl_curve_field "" "DEST" "" ${ARGN})
  if(NOT amcl_curve_field_DEST)
    set(amcl_curve_field_DEST ${field})
  endif()

  amcl_load_curve(${curve})
  set("${amcl_curve_field_DEST}" "${${field}}" PARENT_SCOPE)
endfunction()

# Retrieves the value of <field> for RSA <level>.
#
# If the optional `DEST <name>` argument is supplied, the value is
# saved to <name> in the calling scope. Otherwise, it is saved to
# <field> in the calling scope.
function(amcl_rsa_field field level)
  cmake_parse_arguments(amcl_rsa_field "" "DEST" "" ${ARGN})
  if(NOT amcl_rsa_field_DEST)
    set(amcl_rsa_field_DEST ${field})
  endif()

  amcl_load_rsa(${level})
  set("${amcl_rsa_field_DEST}" "${${field}}" PARENT_SCOPE)
endfunction()
