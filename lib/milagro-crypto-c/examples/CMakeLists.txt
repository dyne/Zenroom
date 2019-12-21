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

foreach(curve ${AMCL_CURVE})
  amcl_curve_field(PF "${curve}")
  amcl_curve_field(TC "${curve}")
  amcl_curve_field(CS "${curve}")

  amcl_configure_file_curve(example_ecdh_ZZZ.c.in example_ecdh_${TC}.c "${curve}" example_ecdh_${TC}_GEN_SRCS)
  add_executable(example_ecdh_${TC} ${example_ecdh_${TC}_GEN_SRCS})
  target_link_libraries(example_ecdh_${TC} PRIVATE amcl_curve_${TC})

  if(TARGET amcl_mpin_${TC})
    amcl_configure_file_curve(example_mpin_ZZZ.c.in example_mpin_${TC}.c "${curve}" example_mpin_${TC}_GEN_SRCS)
    add_executable(example_mpin_${TC} ${example_mpin_${TC}_GEN_SRCS})
    target_link_libraries(example_mpin_${TC} PRIVATE amcl_mpin_${TC})

    amcl_configure_file_curve(example_dvs_ZZZ.c.in example_dvs_${TC}.c "${curve}" example_dvs_${TC}_GEN_SRCS)
    add_executable(example_dvs_${TC} ${example_dvs_${TC}_GEN_SRCS})
    target_link_libraries(example_dvs_${TC} PRIVATE amcl_mpin_${TC})
  endif()

  if(TARGET amcl_wcc_${TC})
    amcl_configure_file_curve(example_wcc_ZZZ.c.in example_wcc_${TC}.c "${curve}" example_wcc_${TC}_GEN_SRCS)
    add_executable(example_wcc_${TC} ${example_wcc_${TC}_GEN_SRCS})
    target_link_libraries(example_wcc_${TC} PRIVATE amcl_wcc_${TC})

    amcl_configure_file_curve(example_wcc_dta_ZZZ.c.in example_wcc_dta_${TC}.c "${curve}" example_wcc_dta_${TC}_GEN_SRCS)
    add_executable(example_wcc_dta_${TC} ${example_wcc_dta_${TC}_GEN_SRCS})
    target_link_libraries(example_wcc_dta_${TC} PRIVATE amcl_wcc_${TC})
  endif()

  if(TARGET amcl_bls_${TC})
    amcl_configure_file_curve(example_bls_ZZZ.c.in example_bls_${TC}.c "${curve}" example_bls_${TC}_GEN_SRCS)
    add_executable(example_bls_${TC} ${example_bls_${TC}_GEN_SRCS})
    target_link_libraries(example_bls_${TC} PRIVATE amcl_bls_${TC})
    
    amcl_configure_file_curve(example_bls_sss_ZZZ.c.in example_bls_sss_${TC}.c "${curve}" example_bls_sss_${TC}_GEN_SRCS)
    add_executable(example_bls_sss_${TC} ${example_bls_sss_${TC}_GEN_SRCS})
    target_link_libraries(example_bls_sss_${TC} PRIVATE amcl_bls_${TC})
  endif()
  
endforeach()

foreach(level ${AMCL_RSA})
  amcl_rsa_field(TFF "${level}")

  amcl_configure_file_rsa(example_rsa_WWW.c.in example_rsa_${TFF}.c "${level}" example_rsa_${TFF}_GEN_SRCS)
  add_executable(example_rsa_${TFF} ${example_rsa_${TFF}_GEN_SRCS})
  target_link_libraries(example_rsa_${TFF} PRIVATE amcl_rsa_${TFF})

endforeach()

if(BUILD_PAILLIER)
  add_executable(example_paillier example_paillier.c)
  target_link_libraries(example_paillier PRIVATE amcl_paillier)
endif()
