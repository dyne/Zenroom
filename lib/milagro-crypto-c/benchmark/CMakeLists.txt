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

  # Curve Benchmark
  amcl_configure_file_curve(benchtest_ec_ZZZ.c.in benchtest_ec_${TC}.c "${curve}" benchtest_ec_${TC}_GEN_SRCS)
  add_executable(benchtest_ec_${TC} ${benchtest_ec_${TC}_GEN_SRCS})
  target_link_libraries(benchtest_ec_${TC} PRIVATE amcl_curve_${TC})

  # Pairing Benchmark
  if(TARGET amcl_pairing_${TC})
    amcl_configure_file_curve(benchtest_pair_ZZZ.c.in benchtest_pair_${TC}.c "${curve}" benchtest_pair_${TC}_GEN_SRCS)
    add_executable(benchtest_pair_${TC} ${benchtest_pair_${TC}_GEN_SRCS})
    target_link_libraries(benchtest_pair_${TC} PRIVATE amcl_pairing_${TC})
  endif()

  # MPIN Benchmark
  if(TARGET amcl_mpin_${TC})
    amcl_configure_file_curve(benchtest_mpin_ZZZ.c.in benchtest_mpin_${TC}.c "${curve}" benchtest_mpin_${TC}_GEN_SRCS)
    add_executable(benchtest_mpin_${TC} ${benchtest_mpin_${TC}_GEN_SRCS})
    target_link_libraries(benchtest_mpin_${TC} PRIVATE amcl_mpin_${TC})
  endif()
  
endforeach()

foreach(level ${AMCL_RSA})
  amcl_rsa_field(TFF "${level}")

  amcl_configure_file_rsa(benchtest_rsa_WWW.c.in benchtest_rsa_${TFF}.c "${level}" benchtest_rsa_${TFF}_GEN_SRCS)
  add_executable(benchtest_rsa_${TFF} ${benchtest_rsa_${TFF}_GEN_SRCS})
  target_link_libraries(benchtest_rsa_${TFF} PRIVATE amcl_rsa_${TFF})
endforeach()

if(${BUILD_PAILLIER})
  amcl_configure_file_core(benchtest_paillier.c.in benchtest_paillier.c benchtest_paillier_GEN_SRCS)
  add_executable(benchtest_paillier ${benchtest_paillier_GEN_SRCS})
  target_link_libraries(benchtest_paillier PRIVATE amcl_paillier)
endif()
