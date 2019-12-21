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

cmake_minimum_required(VERSION 3.1 FATAL_ERROR)

function(amcl_test name source dependencies expected_response)
  add_executable(${name} "${source}")

  target_link_libraries(${name} PRIVATE ${dependencies})

  add_test(NAME ${name}
    COMMAND ${TARGET_SYSTEM_EMULATOR} $<TARGET_FILE:${name}> ${ARGN}
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}/testVectors
  )

  set_tests_properties(${name} PROPERTIES
    PASS_REGULAR_EXPRESSION "${expected_response}"
  )
endfunction()

function(amcl_curve_test curve name source dependencies expected_response)
  if(NOT TARGET ${name})
    amcl_configure_file_curve(${source} ${name}.c ${curve} ${name}_SRC)
    amcl_test(${name} ${${name}_SRC} "${dependencies}" "${expected_response}" ${ARGN})
  endif()
endfunction()

function(amcl_rsa_test level name source dependencies expected_response)
  if(NOT TARGET ${name})
    amcl_configure_file_rsa(${source} ${name}.c ${level} ${name}_SRC)
    amcl_test(${name} ${${name}_SRC} "${dependencies}" "${expected_response}" ${ARGN})
  endif()
endfunction()

function(amcl_rsa_curve_test level curve name source dependencies expected_response)
  if(NOT TARGET ${name})
    amcl_configure_file_rsa_curve(${source} ${name}.c ${level} ${curve} ${name}_SRC)
    amcl_test(${name} ${${name}_SRC} "${dependencies}" "${expected_response}" ${ARGN})
  endif()
endfunction()

################################################
# Basic Tests
################################################
amcl_test(test_octet_consistency test_octet_consistency.c amcl_core "SUCCESS")
amcl_test(test_version test_version.c amcl_core "Version: ${AMCL_VERSION_MAJOR}.${AMCL_VERSION_MINOR}.${AMCL_VERSION_PATCH}")
amcl_test(test_utils test_utils.c amcl_core "SUCCESS")

################################################
# Hash Tests
################################################
amcl_test(test_hash_256 test_hash.c amcl_core "SUCCESS" "sha/256/SHA256ShortMsg.rsp" "sha256")
amcl_test(test_hash_384 test_hash.c amcl_core "SUCCESS" "sha/384/SHA384ShortMsg.rsp" "sha384")
amcl_test(test_hash_512 test_hash.c amcl_core "SUCCESS" "sha/512/SHA512ShortMsg.rsp" "sha512")

################################################
# AES-GCM Tests
################################################
amcl_test(test_gcm_encrypt_128      test_gcm_encrypt.c amcl_core "SUCCESS" "gcm/gcmEncryptExtIV128.rsp" "")
amcl_test(test_gcm_encrypt_256      test_gcm_encrypt.c amcl_core "SUCCESS" "gcm/gcmEncryptExtIV256.rsp" "")
amcl_test(test_gcm_decrypt_128      test_gcm_decrypt.c amcl_core "SUCCESS" "gcm/gcmDecrypt128.rsp"      "")
amcl_test(test_gcm_decrypt_256      test_gcm_decrypt.c amcl_core "SUCCESS" "gcm/gcmDecrypt256.rsp"      "")
amcl_test(test_aes_encrypt_ECB_128  test_aes_encrypt.c amcl_core "SUCCESS" "aes/ECBMMT128.rsp"          "ECB")
amcl_test(test_aes_encrypt_ECB_256  test_aes_encrypt.c amcl_core "SUCCESS" "aes/ECBMMT256.rsp"          "ECB")
amcl_test(test_aes_encrypt_CBC_128  test_aes_encrypt.c amcl_core "SUCCESS" "aes/CBCMMT128.rsp"          "CBC")
amcl_test(test_aes_encrypt_CFB1_128 test_aes_encrypt.c amcl_core "SUCCESS" "aes/CFB8MMT128.rsp"         "CFB1")
amcl_test(test_aes_encrypt_CBC_256  test_aes_encrypt.c amcl_core "SUCCESS" "aes/CBCMMT256.rsp"          "CBC")
amcl_test(test_aes_encrypt_CTR_128  test_aes_encrypt.c amcl_core "SUCCESS" "aes/amcl_CTRMCL128.rsp"     "CTR")
amcl_test(test_aes_encrypt_CTR_256  test_aes_encrypt.c amcl_core "SUCCESS" "aes/amcl_CTRMCL256.rsp"     "CTR")
amcl_test(test_aes_encrypt_CFB1_256 test_aes_encrypt.c amcl_core "SUCCESS" "aes/CFB8MMT256.rsp"         "CFB1")
amcl_test(test_aes_decrypt_ECB_128  test_aes_decrypt.c amcl_core "SUCCESS" "aes/ECBMMT128.rsp"          "ECB")
amcl_test(test_aes_decrypt_ECB_256  test_aes_decrypt.c amcl_core "SUCCESS" "aes/ECBMMT256.rsp"          "ECB")
amcl_test(test_aes_decrypt_CBC_128  test_aes_decrypt.c amcl_core "SUCCESS" "aes/CBCMMT128.rsp"          "CBC")
amcl_test(test_aes_decrypt_CFB1_128 test_aes_decrypt.c amcl_core "SUCCESS" "aes/CFB8MMT128.rsp"         "CFB1")
amcl_test(test_aes_decrypt_CBC_256  test_aes_decrypt.c amcl_core "SUCCESS" "aes/CBCMMT256.rsp"          "CBC")
amcl_test(test_aes_decrypt_CTR_128  test_aes_decrypt.c amcl_core "SUCCESS" "aes/amcl_CTRMCL128.rsp"     "CTR")
amcl_test(test_aes_decrypt_CTR_256  test_aes_decrypt.c amcl_core "SUCCESS" "aes/amcl_CTRMCL256.rsp"     "CTR")
amcl_test(test_aes_decrypt_CFB1_256 test_aes_decrypt.c amcl_core "SUCCESS" "aes/CFB8MMT256.rsp"         "CFB1")

################################################
# Curve Tests
################################################
foreach(curve ${AMCL_CURVE})
  amcl_curve_field(BD "${curve}")
  amcl_curve_field(PF "${curve}")
  amcl_curve_field(TC "${curve}")
  amcl_curve_field(TF "${curve}")
  amcl_curve_field(CS "${curve}")
  
  amcl_curve_test(${curve} test_big_arithmetics_${BD} test_big_arithmetics_XXX.c.in amcl_curve_${TC} "SUCCESS" "big/test_vector_big.txt")
  amcl_curve_test(${curve} test_big_consistency_${BD} test_big_consistency_XXX.c.in amcl_curve_${TC} "SUCCESS")
  amcl_curve_test(${curve} test_ecc_${TC}             test_ecc_ZZZ.c.in             amcl_curve_${TC} "SUCCESS")
  # TODO amcl_curve_test(${curve} test_fp_arithmetics_${TF}  test_fp_arithmetics_YYY.c.in  amcl_curve_${TC} "SUCCESS" "fp/test_vector_${TF}.txt")

  if(NOT ${TC} MATCHES "^NUMS[0-9]+E$")
    amcl_curve_test(${curve} test_ecp_arithmetics_${TC} test_ecp_arithmetics_ZZZ.c.in amcl_curve_${TC} "SUCCESS" "ecp/test_vector_${TC}.txt")
  endif()

  if(curve STREQUAL "NIST256")
    amcl_curve_test(${curve} test_ecdh_${TC}             test_ecdh_ZZZ.c.in          amcl_curve_${TC} "SUCCESS" "ecdh/P-256/KAS_ECC_CDH_PrimitiveTest.txt")
    amcl_curve_test(${curve} test_ecdsa_keypair_${TC}    test_ecdsa_keypair_ZZZ.c.in amcl_curve_${TC} "SUCCESS" "ecdsa/P-256/KeyPair.rsp")
    amcl_curve_test(${curve} test_ecdsa_sign_${TC}_256   test_ecdsa_sign_ZZZ.c.in    amcl_curve_${TC} "SUCCESS" "ecdsa/P-256/sha256Sign.rsp" "sha256")
    amcl_curve_test(${curve} test_ecdsa_sign_${TC}_512   test_ecdsa_sign_ZZZ.c.in    amcl_curve_${TC} "SUCCESS" "ecdsa/P-256/sha512Sign.rsp" "sha512")
    amcl_curve_test(${curve} test_ecdsa_verify_${TC}_256 test_ecdsa_verify_ZZZ.c.in  amcl_curve_${TC} "SUCCESS" "ecdsa/P-256/sha256Verify.rsp" "sha256")
    amcl_curve_test(${curve} test_ecdsa_verify_${TC}_512 test_ecdsa_verify_ZZZ.c.in  amcl_curve_${TC} "SUCCESS" "ecdsa/P-256/sha512Verify.rsp" "sha512")
  endif()

  if(curve STREQUAL "NIST384")
    amcl_curve_test(${curve} test_ecdh_${TC}             test_ecdh_ZZZ.c.in          amcl_curve_${TC} "SUCCESS" "ecdh/P-384/KAS_ECC_CDH_PrimitiveTest.txt")
    amcl_curve_test(${curve} test_ecdsa_keypair_${TC}    test_ecdsa_keypair_ZZZ.c.in amcl_curve_${TC} "SUCCESS" "ecdsa/P-384/KeyPair.rsp")
    amcl_curve_test(${curve} test_ecdsa_sign_${TC}_256   test_ecdsa_sign_ZZZ.c.in    amcl_curve_${TC} "SUCCESS" "ecdsa/P-384/sha256Sign.rsp" "sha256")
    amcl_curve_test(${curve} test_ecdsa_sign_${TC}_384   test_ecdsa_sign_ZZZ.c.in    amcl_curve_${TC} "SUCCESS" "ecdsa/P-384/sha384Sign.rsp" "sha384")
    amcl_curve_test(${curve} test_ecdsa_sign_${TC}_512   test_ecdsa_sign_ZZZ.c.in    amcl_curve_${TC} "SUCCESS" "ecdsa/P-384/sha512Sign.rsp" "sha512")
    amcl_curve_test(${curve} test_ecdsa_verify_${TC}_256 test_ecdsa_verify_ZZZ.c.in  amcl_curve_${TC} "SUCCESS" "ecdsa/P-384/sha256Verify.rsp" "sha256")
    amcl_curve_test(${curve} test_ecdsa_verify_${TC}_384 test_ecdsa_verify_ZZZ.c.in  amcl_curve_${TC} "SUCCESS" "ecdsa/P-384/sha384Verify.rsp" "sha384")
    amcl_curve_test(${curve} test_ecdsa_verify_${TC}_512 test_ecdsa_verify_ZZZ.c.in  amcl_curve_${TC} "SUCCESS" "ecdsa/P-384/sha512Verify.rsp" "sha512")
  endif()

  if(curve STREQUAL "NIST521")
    amcl_curve_test(${curve} test_ecdh_${TC}             test_ecdh_ZZZ.c.in          amcl_curve_${TC} "SUCCESS" "ecdh/P-521/KAS_ECC_CDH_PrimitiveTest.txt")
    amcl_curve_test(${curve} test_ecdsa_keypair_${TC}    test_ecdsa_keypair_ZZZ.c.in amcl_curve_${TC} "SUCCESS" "ecdsa/P-521/KeyPair.rsp")
    amcl_curve_test(${curve} test_ecdsa_sign_${TC}_256   test_ecdsa_sign_ZZZ.c.in    amcl_curve_${TC} "SUCCESS" "ecdsa/P-521/sha256Sign.rsp" "sha256")
    amcl_curve_test(${curve} test_ecdsa_sign_${TC}_512   test_ecdsa_sign_ZZZ.c.in    amcl_curve_${TC} "SUCCESS" "ecdsa/P-521/sha512Sign.rsp" "sha512")
    amcl_curve_test(${curve} test_ecdsa_verify_${TC}_256 test_ecdsa_verify_ZZZ.c.in  amcl_curve_${TC} "SUCCESS" "ecdsa/P-521/sha256Verify.rsp" "sha256")
    amcl_curve_test(${curve} test_ecdsa_verify_${TC}_512 test_ecdsa_verify_ZZZ.c.in  amcl_curve_${TC} "SUCCESS" "ecdsa/P-521/sha512Verify.rsp" "sha512")
  endif()

  ################################################
  # Pairing Friendly Curve Tests
  ################################################
  if(NOT ${PF} STREQUAL "NOT")
    # TODO amcl_curve_test(${curve} test_fp2_arithmetics_${TC}  test_fp2_arithmetics_YYY.c.in  amcl_pairing_${TC} "SUCCESS" "fp2/test_vector_${TC}.txt")
    # TODO amcl_curve_test(${curve} test_fp4_arithmetics_${TC}  test_fp4_arithmetics_YYY.c.in  amcl_pairing_${TC} "SUCCESS" "fp4/test_vector_${TC}.txt")
    if(CS STREQUAL "128")
      # TODO amcl_curve_test(${curve} test_fp12_arithmetics_${TC}  test_fp12_arithmetics_YYY.c.in  amcl_pairing_${TC} "SUCCESS" "fp12/test_vector_${TC}.txt")
      amcl_curve_test(${curve} test_ecp2_arithmetics_${TC} test_ecp2_arithmetics_ZZZ.c.in amcl_pairing_${TC} "SUCCESS" "ecp2/test_vector_${TC}.txt")
    elseif(CS STREQUAL "192")
      # TODO amcl_curve_test(${curve} test_fp8_arithmetics_${TC}  test_fp8_arithmetics_YYY.c.in  amcl_pairing_${TC} "SUCCESS" "fp8/test_vector_${TC}.txt")
      # TODO amcl_curve_test(${curve} test_fp24_arithmetics_${TC}  test_fp24_arithmetics_YYY.c.in  amcl_pairing_${TC} "SUCCESS" "fp24/test_vector_${TC}.txt")
      amcl_curve_test(${curve} test_ecp4_arithmetics_${TC} test_ecp4_arithmetics_ZZZ.c.in amcl_pairing_${TC} "SUCCESS" "ecp4/test_vector_${TC}.txt")
    elseif(CS STREQUAL "256")
      # TODO amcl_curve_test(${curve} test_fp8_arithmetics_${TC}  test_fp8_arithmetics_YYY.c.in  amcl_pairing_${TC} "SUCCESS" "fp8/test_vector_${TC}.txt")
      # TODO amcl_curve_test(${curve} test_fp16_arithmetics_${TC}  test_fp16_arithmetics_YYY.c.in  amcl_pairing_${TC} "SUCCESS" "fp16/test_vector_${TC}.txt")
      # TODO amcl_curve_test(${curve} test_fp48_arithmetics_${TC}  test_fp48_arithmetics_YYY.c.in  amcl_pairing_${TC} "SUCCESS" "fp48/test_vector_${TC}.txt")
      amcl_curve_test(${curve} test_ecp8_arithmetics_${TC} test_ecp8_arithmetics_ZZZ.c.in amcl_pairing_${TC} "SUCCESS" "ecp8/test_vector_${TC}.txt")
    endif(CS STREQUAL "128")
    amcl_curve_test(${curve} test_pair_${TC}             test_pair_ZZZ.c.in             amcl_pairing_${TC} "SUCCESS")

    if(CMAKE_SYSTEM_NAME MATCHES "Linux")
      # Test arithmetics debug output functions - Linux specific code
      amcl_curve_test(${curve} test_output_functions_${TC} test_output_functions_ZZZ.c.in amcl_pairing_${TC} "SUCCESS" "output/test_vector_${TC}_${WORD_SIZE}.txt" "stdout.out")
    endif(CMAKE_SYSTEM_NAME MATCHES "Linux")

    ################################################
    # MPIN Tests
    ################################################
    if(BUILD_MPIN)
      amcl_curve_test(${curve} test_mpin_${TC}              test_mpin_ZZZ.c.in              amcl_mpin_${TC} "SUCCESS Error Code 0")
      amcl_curve_test(${curve} test_mpin_sign_${TC}         test_mpin_sign_ZZZ.c.in         amcl_mpin_${TC} "TEST PASSED")
      amcl_curve_test(${curve} test_mpin_good_${TC}         test_mpin_good_ZZZ.c.in         amcl_mpin_${TC} "SUCCESS Error Code 0")
      amcl_curve_test(${curve} test_mpin_bad_pin_${TC}      test_mpin_bad_pin_ZZZ.c.in      amcl_mpin_${TC} "FAILURE")
      amcl_curve_test(${curve} test_mpin_bad_token_${TC}    test_mpin_bad_token_ZZZ.c.in    amcl_mpin_${TC} "FAILURE")
      amcl_curve_test(${curve} test_mpin_tp_${TC}           test_mpin_tp_ZZZ.c.in           amcl_mpin_${TC} "SUCCESS Error Code 0")
      amcl_curve_test(${curve} test_mpin_expired_tp_${TC}   test_mpin_expired_tp_ZZZ.c.in   amcl_mpin_${TC} "FAILURE Invalid Token Error Code -19")
      amcl_curve_test(${curve} test_mpin_dvs_${TC}          test_mpin_dvs_ZZZ.c.in          amcl_mpin_${TC} "SUCCESS Error Code 0")
      amcl_curve_test(${curve} test_mpin_dvs_wrong_pk_${TC} test_mpin_dvs_wrong_pk_ZZZ.c.in amcl_mpin_${TC} "FAILURE Signature Verification Error Code -19")
      amcl_curve_test(${curve} test_mpin_random_${TC}       test_mpin_random_ZZZ.c.in       amcl_mpin_${TC} "SUCCESS Error Code 0")
      amcl_curve_test(${curve} test_mpinfull_sha256_${TC}   test_mpinfull_ZZZ.c.in          amcl_mpin_${TC} "SUCCESS" "sha256")
      amcl_curve_test(${curve} test_mpinfull_sha384_${TC}   test_mpinfull_ZZZ.c.in          amcl_mpin_${TC} "SUCCESS" "sha384")
      amcl_curve_test(${curve} test_mpinfull_sha512_${TC}   test_mpinfull_ZZZ.c.in          amcl_mpin_${TC} "SUCCESS" "sha512")
      amcl_curve_test(${curve} test_mpinfull_tp_${TC}       test_mpinfull_tp_ZZZ.c.in       amcl_mpin_${TC} "SUCCESS")
      amcl_curve_test(${curve} test_mpinfull_onepass_${TC}  test_mpinfull_onepass_ZZZ.c.in  amcl_mpin_${TC} "SUCCESS")
      amcl_curve_test(${curve} test_mpinfull_random_${TC}   test_mpinfull_random_ZZZ.c.in   amcl_mpin_${TC} "SUCCESS")
      if(curve STREQUAL "BN254CX")
	     amcl_curve_test(${curve} test_mpin_vectors_dta_${TC}    test_mpin_vectors_dta_ZZZ.c.in      amcl_mpin_${TC} "SUCCESS" "mpin/BN254_CX.txt")
      endif()
      if(curve STREQUAL "BLS381")
	     amcl_curve_test(${curve} test_mpin_vectors_${TC}    test_mpin_vectors_ZZZ.c.in      amcl_mpin_${TC} "SUCCESS" "mpin/BLS381.txt")
      endif()
    endif()

    ################################################
    # WCC Tests
    ################################################
    if(BUILD_WCC)
      amcl_curve_test(${curve} test_wcc_${TC} test_wcc_ZZZ.c.in amcl_wcc_${TC} "SUCCESS")
      amcl_curve_test(${curve} test_wcc_random_${TC} test_wcc_random_ZZZ.c.in amcl_wcc_${TC} "SUCCESS")
      amcl_curve_test(${curve} test_wcc_invalid_points_${TC} test_wcc_invalid_points_ZZZ.c.in amcl_wcc_${TC} "SUCCESS")
      amcl_curve_test(${curve} test_wcc_bad_sender_key_${TC} test_wcc_bad_sender_key_ZZZ.c.in amcl_wcc_${TC} "SUCCESS")
      amcl_curve_test(${curve} test_wcc_bad_receiver_key_${TC} test_wcc_bad_receiver_key_ZZZ.c.in amcl_wcc_${TC} "SUCCESS")
    endif()

    ################################################
    # BLS Tests
    ################################################
    if(BUILD_BLS)
      amcl_curve_test(${curve} test_bls_${TC} test_bls_ZZZ.c.in amcl_bls_${TC} "SUCCESS")
      amcl_curve_test(${curve} test_bls_sss_${TC} test_bls_sss_ZZZ.c.in amcl_bls_${TC} "SUCCESS")      
    endif()
    
  endif()
endforeach()

################################################
# RSA Tests
################################################
foreach(level ${AMCL_RSA})
  amcl_rsa_field(BD "${level}")
  amcl_rsa_field(TFF "${level}")

  amcl_rsa_test(${level} test_big_arithmetics_${BD} test_big_arithmetics_XXX.c.in amcl_rsa_${TFF} "SUCCESS" "big/test_vector_big.txt")
  amcl_rsa_test(${level} test_big_consistency_${BD} test_big_consistency_XXX.c.in amcl_rsa_${TFF} "SUCCESS")
  amcl_rsa_test(${level} test_ff_consistency_${TFF}  test_ff_consistency_WWW.c.in  amcl_rsa_${TFF} "SUCCESS")
  amcl_rsa_test(${level} test_rsa_${TFF}            test_rsa_WWW.c.in             amcl_rsa_${TFF} "SUCCESS")
endforeach()

################################################
# X509 Tests
################################################
if(BUILD_X509)
  foreach(level ${AMCL_RSA})
    foreach(curve ${AMCL_CURVE})

      set(deps "amcl_x509;amcl_rsa_${level};amcl_curve_${curve}")
      
      if (level STREQUAL "2048" AND curve STREQUAL "NIST256")
	amcl_rsa_curve_test(${level} ${curve} test_x509_${level}_${curve}_1   test_x509_WWW_ZZZ.c.in     "${deps}" "SUCCESS" "x509/2048_P256/x509-vect.txt")
	amcl_rsa_curve_test(${level} ${curve} test_x509_${level}_${curve}_2   test_x509_WWW_ZZZ.c.in     "${deps}" "SUCCESS" "x509/2048_P256/pkits-vect.txt")
	amcl_rsa_curve_test(${level} ${curve} test_rsa_sign_${level}_${curve} test_rsa_sign_WWW_ZZZ.c.in "${deps}" "SUCCESS" "rsa/2048/pkcs-vect.txt")
      endif()

      if (level STREQUAL "4096" AND curve STREQUAL "NIST256")
	amcl_rsa_curve_test(${level} ${curve} test_x509_${level}_${curve}_1   test_x509_WWW_ZZZ.c.in     "${deps}" "SUCCESS" "x509/4096/x509-vect.txt")
	amcl_rsa_curve_test(${level} ${curve} test_rsa_sign_${level}_${curve} test_rsa_sign_WWW_ZZZ.c.in "${deps}" "SUCCESS" "rsa/4096/pkcs-vect.txt")
      endif()

      if (level STREQUAL "3072" AND curve STREQUAL "NIST384")
	amcl_rsa_curve_test(${level} ${curve} test_x509_${level}_${curve}_1   test_x509_WWW_ZZZ.c.in     "${deps}" "SUCCESS" "x509/3072_P384/x509-vect.txt")
	amcl_rsa_curve_test(${level} ${curve} test_rsa_sign_${level}_${curve} test_rsa_sign_WWW_ZZZ.c.in "${deps}" "SUCCESS" "rsa/3072/pkcs-vect.txt")
      endif()

      if (curve STREQUAL "NIST521")
	amcl_rsa_curve_test(${level} ${curve} test_x509_${level}_${curve}_1   test_x509_WWW_ZZZ.c.in     "${deps}" "SUCCESS" "x509/P521/x509-vect.txt")
      endif()

      if (level STREQUAL "2048" AND curve STREQUAL "C25519")
	amcl_rsa_curve_test(${level} ${curve} test_rsa_sign_${level}_${curve} test_rsa_sign_WWW_ZZZ.c.in "${deps}" "SUCCESS" "rsa/2048/pkcs-vect.txt")
      endif()

    endforeach()
  endforeach()
endif()

################################################
# Paillier Tests
################################################

if(BUILD_PAILLIER)
  set(deps "amcl_core;amcl_paillier")

  foreach(level 2048 4096)
    amcl_rsa_field(BD "${level}")
    amcl_rsa_field(TFF "${level}")

    amcl_rsa_test(${level} test_big_arithmetics_${BD} test_big_arithmetics_XXX.c.in "${deps}" "SUCCESS" "big/test_vector_big.txt")
    amcl_rsa_test(${level} test_big_consistency_${BD} test_big_consistency_XXX.c.in "${deps}" "SUCCESS")
    amcl_rsa_test(${level} test_ff_consistency_${TFF} test_ff_consistency_WWW.c.in  "${deps}" "SUCCESS")
  endforeach()

  amcl_test(test_paillier_consistency test_paillier_consistency.c "${deps}" "SUCCESS")
  amcl_test(test_paillier_decrypt test_paillier_decrypt.c "${deps}" "SUCCESS" "paillier/decrypt.txt")
  amcl_test(test_paillier_encrypt test_paillier_encrypt.c "${deps}" "SUCCESS" "paillier/encrypt.txt")
  amcl_test(test_paillier_add test_paillier_add.c "${deps}" "SUCCESS" "paillier/add.txt")
  amcl_test(test_paillier_mult test_paillier_mult.c "${deps}" "SUCCESS" "paillier/mult.txt")
  amcl_test(test_paillier_keygen test_paillier_keygen.c "${deps}" "SUCCESS" "paillier/keygen.txt")
endif()
