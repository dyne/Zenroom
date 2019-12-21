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

include(PythonSiteDirs)

foreach(curve ${AMCL_CURVE})
  amcl_curve_field(PF "${curve}")
  amcl_curve_field(TC "${curve}")

  if(TARGET amcl_mpin_${TC})
    amcl_configure_file_curve(mpin_ZZZ.py.in            mpin_${TC}.py            ${curve} amcl_mpin_${TC}_GEN_PYS)
    amcl_configure_file_curve(TimeMPIN_ZZZ.py.in        TimeMPIN_${TC}.py        ${curve} __no_install)
    amcl_configure_file_curve(TestMPINInstall_ZZZ.py.in TestMPINInstall_${TC}.py ${curve} __no_install)

    install(FILES "${amcl_mpin_${TC}_GEN_PYS}" DESTINATION ${PYTHON3_SITE_PACKAGES})
  
    add_test(test_python_mpin_install_${TC} python3 TestMPINInstall_${TC}.py)

    # Set the LD_LIBRARY_PATH or equivalent to the libraries can be
    # loaded when running the test.
    if(CMAKE_SYSTEM_NAME MATCHES "Darwin")
      set(ld_library_path_var "DYLD_LIBRARY_PATH")
    elseif(CMAKE_SYSTEM_NAME MATCHES "Linux")
      set(ld_library_path_var "LD_LIBRARY_PATH")
    elseif(CMAKE_SYSTEM_NAME MATCHES "Windows")
      set(ld_library_path_var "PATH")
    endif()
    set_tests_properties(test_python_mpin_install_${TC} PROPERTIES
      ENVIRONMENT "${ld_library_path_var}=${CMAKE_LIBRARY_OUTPUT_DIRECTORY}")

  endif()

  if(TARGET amcl_wcc_${TC})
    amcl_configure_file_curve(wcc_ZZZ.py.in wcc_${TC}.py ${curve} amcl_wcc_${TC}_GEN_PYS)
    install(FILES "${amcl_wcc_${TC}_GEN_PYS}" DESTINATION ${PYTHON3_SITE_PACKAGES})
  endif()

  if(TARGET amcl_bls_${TC})
    amcl_configure_file_curve(bls_ZZZ.py.in bls_${TC}.py ${curve} amcl_bls_${TC}_GEN_PYS)
    install(FILES "${amcl_bls_${TC}_GEN_PYS}" DESTINATION ${PYTHON3_SITE_PACKAGES})
  endif()
  
endforeach()
