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

  amcl_configure_file_curve(testecdh_ZZZ.c.in testecdh_${TC}.c "${curve}" testecdh_${TC}_GEN_SRCS)
  add_executable(testecdh_${TC} ${testecdh_${TC}_GEN_SRCS})
  target_link_libraries(testecdh_${TC} PRIVATE amcl_curve_${TC})

  if(TARGET amcl_mpin_${TC})
    amcl_configure_file_curve(testmpin_ZZZ.c.in testmpin_${TC}.c "${curve}" testmpin_${TC}_GEN_SRCS)
    add_executable(testmpin_${TC} ${testmpin_${TC}_GEN_SRCS})
    target_link_libraries(testmpin_${TC} PRIVATE amcl_mpin_${TC})

    amcl_configure_file_curve(testdvs_ZZZ.c.in testdvs_${TC}.c "${curve}" testdvs_${TC}_GEN_SRCS)
    add_executable(testdvs_${TC} ${testdvs_${TC}_GEN_SRCS})
    target_link_libraries(testdvs_${TC} PRIVATE amcl_mpin_${TC})
  endif()

  if(TARGET amcl_wcc_${TC})
    amcl_configure_file_curve(testwcc_ZZZ.c.in testwcc_${TC}.c "${curve}" testwcc_${TC}_GEN_SRCS)
    add_executable(testwcc_${TC} ${testwcc_${TC}_GEN_SRCS})
    target_link_libraries(testwcc_${TC} PRIVATE amcl_wcc_${TC})

    amcl_configure_file_curve(testwcc_dta_ZZZ.c.in testwcc_dta_${TC}.c "${curve}" testwcc_dta_${TC}_GEN_SRCS)
    add_executable(testwcc_dta_${TC} ${testwcc_dta_${TC}_GEN_SRCS})
    target_link_libraries(testwcc_dta_${TC} PRIVATE amcl_wcc_${TC})
  endif()

endforeach()

foreach(level ${AMCL_RSA})
  amcl_rsa_field(TFF "${level}")

  amcl_configure_file_rsa(testrsa_WWW.c.in testrsa_${TFF}.c "${level}" testrsa_${TFF}_GEN_SRCS)
  add_executable(testrsa_${TFF} ${testrsa_${TFF}_GEN_SRCS})
  target_link_libraries(testrsa_${TFF} PRIVATE amcl_rsa_${TFF})

endforeach()
