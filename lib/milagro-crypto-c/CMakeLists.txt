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

file(STRINGS "VERSION" VERSION_STRING)
project(AMCL VERSION "${VERSION_STRING}" LANGUAGES C)

##################################################
# Helper Macros
##################################################
macro(log var)
  message(STATUS "${var}: ${${var}}")
endmacro()

macro(set_if_unset var val)
  if(NOT ${var})
    set(${var} "${val}")
  endif()
  log(${var})
endmacro()

##################################################
# Includes
##################################################
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
include(AMCLExpand)
include(CMakeDependentOption)
include(CTest)
include(DetermineWordSize)
include(GNUInstallDirs)
include(SetOSVariable)

##################################################
# Internal settings
##################################################
message(STATUS "AMCL")
log(PROJECT_VERSION)
log(CMAKE_GENERATOR)

add_definitions(-DCMAKE)

set(AMCL_VERSION       ${PROJECT_VERSION})
set(AMCL_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
set(AMCL_VERSION_MINOR ${PROJECT_VERSION_MINOR})
set(AMCL_VERSION_PATCH ${PROJECT_VERSION_PATCH})

set(AMCL_SOVERSION ${AMCL_VERSION_MAJOR})

if(CMAKE_COMPILER_IS_GNUCC)
    execute_process(COMMAND ${CMAKE_C_COMPILER} -dumpversion
                    OUTPUT_VARIABLE GCC_VERSION)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=c99 -static-libgcc -Wall -Wextra -Wno-strict-prototypes -Wunused-value -Wcast-align -Wunused-variable -Wundef -Wformat-security")

    if (GCC_VERSION VERSION_GREATER 4.8 OR GCC_VERSION VERSION_EQUAL 4.8)
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wshadow")
        set(CMAKE_C_FLAGS_ASAN    "-O0 -g3 -fsanitize=address")
    else (GCC_VERSION VERSION_GREATER 4.8 OR GCC_VERSION VERSION_EQUAL 4.8)
        message(STATUS "GCC 4.8 required to run address sanitizer - please upgrade your installation")
    endif(GCC_VERSION VERSION_GREATER 4.8 OR GCC_VERSION VERSION_EQUAL 4.8)

    set(CMAKE_C_FLAGS_RELEASE     "-O2")
    set(CMAKE_C_FLAGS_DEBUG       "-O0 -g3")
    set(CMAKE_C_FLAGS_COVERAGE    "-O0 -g3 --coverage")
    set(CMAKE_C_FLAGS_CHECK       "-O2 -Werror")
    set(CMAKE_C_FLAGS_CHECKFULL   "${CMAKE_C_FLAGS_CHECK} -Wcast-qual")
endif(CMAKE_COMPILER_IS_GNUCC)

if(CMAKE_BUILD_TYPE STREQUAL "Coverage")
    set(CMAKE_SHARED_LINKER_FLAGS "--coverage")
endif(CMAKE_BUILD_TYPE STREQUAL "Coverage")

##################################################
# Options
##################################################
### Build Type ###
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Choose type of build." FORCE)
endif()
set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Release" "Debug" "Coverage" "ASan" "Check" "CheckFull")
log(CMAKE_BUILD_TYPE)

### Configurations ###
set_if_unset(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bin)
set_if_unset(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib)
set_if_unset(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib)
log(CMAKE_INSTALL_PREFIX)

### Options ###
option(BUILD_SHARED_LIBS "Build shared libraries" ON)
log(BUILD_SHARED_LIBS)

set(AMCL_PREFIX "${AMCL_PREFIX}" CACHE STRING "Prefix exported functions")
log(AMCL_PREFIX)

option(BUILD_BENCHMARKS  "Build benchmarks"       ON)
option(BUILD_DOCS        "Build docs"             ON)
option(BUILD_EXAMPLES    "Build examples"         ON)
cmake_dependent_option(BUILD_PYTHON "Build Python" OFF "BUILD_SHARED_LIBS" OFF)
log(BUILD_BENCHMARKS)
log(BUILD_DOCS)
log(BUILD_EXAMPLES)
log(BUILD_PYTHON)
log(BUILD_TESTING) # added by 'include(CTest)'

option(BUILD_MPIN     "Build MPIN"     ON)
option(BUILD_WCC      "Build WCC"      ON)
option(BUILD_X509     "BUild X509"     ON)
option(BUILD_BLS      "Build BLS"      ON)
option(BUILD_PAILLIER "Build Paillier" OFF)
log(BUILD_MPIN)
log(BUILD_WCC)
log(BUILD_X509)
log(BUILD_BLS)
log(BUILD_PAILLIER)

option(DEBUG_REDUCE "Print debug message for field reduction" OFF)
option(DEBUG_NORM "Detect digit overflow" OFF)
option(GET_STATS "Debug statistics" OFF)
log(DEBUG_REDUCE)
log(DEBUG_NORM)
log(GET_STATS)

### /include subdir ###
set(INSTALL_INCLUDESUBDIR "${CMAKE_INSTALL_INCLUDEDIR}/amcl")
log(CMAKE_INSTALL_INCLUDEDIR)
log(INSTALL_INCLUDESUBDIR)

### Word/Chunk Size ###
determine_word_size(DEFAULT_WORD_SIZE)
set(WORD_SIZE ${DEFAULT_WORD_SIZE} CACHE STRING "Word length in bits. See ./include/arch.h")
set_property(CACHE WORD_SIZE PROPERTY STRINGS "16;32;64")
log(WORD_SIZE)

if(WORD_SIZE STREQUAL "")
  message(FATAL_ERROR "Must explicitly set WORD_SIZE.")
endif()

### RSA Levels ###
amcl_supported_rsa_levels(AMCL_RSA_LEVELS ${WORD_SIZE})
set(AMCL_RSA "${AMCL_RSA_LEVELS}" CACHE STRING "RSA levels of security supported. See ./include/rsa_WWW.h")
set_property(CACHE AMCL_RSA PROPERTY STRINGS ${AMCL_RSA_LEVELS})
string(REPLACE "," ";" AMCL_RSA "${AMCL_RSA}")
log(AMCL_RSA)

### Curves ###
amcl_supported_curves(AMCL_CURVE_NAMES ${WORD_SIZE})
set(AMCL_CURVE "${AMCL_CURVE_NAMES}" CACHE STRING "Choice of Field. See ./include/amcl.h")
set_property(CACHE AMCL_CURVE PROPERTY STRINGS ${AMCL_CURVE_NAMES})
string(REPLACE "," ";" AMCL_CURVE "${AMCL_CURVE}")
log(AMCL_CURVE)

### MPIN ###
if(BUILD_MPIN)
  set(AMCL_MAXPIN 10000 CACHE STRING "Maximum PIN value. See ./include/mpin_ZZZ.h for explanation.")
  set(AMCL_PBLEN 14 CACHE STRING "Maximum PIN value in bits. See ./include/mpin_ZZZ.h for explanation.")
  log(AMCL_MAXPIN)
  log(AMCL_PBLEN)
endif()

### PBC ###
if(BUILD_MPIN OR BUILD_WCC)
  set(PBC_TIME_PERMIT_TESTS 10 CACHE STRING "Number of days in the future to test M-PIN/WCC time permits")
  set(PBC_RANDOM_TESTS 5 CACHE STRING "Number of random M-PIN/WCC tests")
  log(PBC_TIME_PERMIT_TESTS)
  log(PBC_RANDOM_TESTS)
endif()

##################################################
# AMCL_Core Library
##################################################
amcl_configure_file_core(include/amcl.h.in include/amcl.h amcl_core_GEN_HDRS)
amcl_configure_file_core(include/arch.h.in include/arch.h amcl_core_GEN_HDRS)

amcl_generate_SC(SC)
amcl_generate_RSL(RSL)
amcl_configure_file_core(include/version.h.in include/version.h amcl_core_GEN_HDRS)
unset(SC)
unset(RSL)

add_library(amcl_core
  src/hash.c
  src/rand.c
  src/randapi.c
  src/aes.c
  src/gcm.c
  src/oct.c
  src/utils.c
  src/version.c
)
list(APPEND AMCL_LIBRARIES amcl_core)

set_target_properties(amcl_core PROPERTIES
  EXPORT_NAME core
  VERSION ${AMCL_VERSION}
  SOVERSION ${AMCL_SOVERSION}
)

target_include_directories(amcl_core PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

install(TARGETS amcl_core
  EXPORT AMCLTargets
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

install(FILES
  ${amcl_core_GEN_HDRS}
  include/utils.h
  include/randapi.h
  DESTINATION ${INSTALL_INCLUDESUBDIR}
)

if (BUILD_MPIN OR BUILD_WCC OR BUILD_BLS)
  amcl_configure_file_core(include/config_test.h.in include/config_test.h amcl_core_pbc_GEN_HDRS)

  target_sources(amcl_core PRIVATE src/pbc_support.c)

  install(FILES
    ${amcl_core_pbc_GEN_HDRS}
    include/pbc_support.h
    DESTINATION ${INSTALL_INCLUDESUBDIR}
  )
endif()

if (NOT AMCL_RSA STREQUAL "")
  target_sources(amcl_core PRIVATE src/rsa_support.c)

  install(FILES
    include/rsa_support.h
    DESTINATION ${INSTALL_INCLUDESUBDIR}
  )
endif()

if (NOT AMCL_CURVE STREQUAL "")
  target_sources(amcl_core PRIVATE src/ecdh_support.c)

  install(FILES
    include/ecdh_support.h
    DESTINATION ${INSTALL_INCLUDESUBDIR}
  )
endif()

##################################################
# AMCL_X509 Library
##################################################
if(BUILD_X509)
  message(STATUS "Build libamcl_x509")
  add_library(amcl_x509
    src/x509.c
  )
  list(APPEND AMCL_LIBRARIES amcl_x509)

  set_target_properties(amcl_x509 PROPERTIES
    EXPORT_NAME x509
    VERSION ${AMCL_VERSION}
    SOVERSION ${AMCL_SOVERSION}
  )

  target_include_directories(amcl_x509 PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
  )

  target_link_libraries(amcl_x509 PUBLIC
    amcl_core
  )

  install(TARGETS amcl_x509
    EXPORT AMCLTargets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  )

  install(FILES
    include/x509.h
    DESTINATION ${INSTALL_INCLUDESUBDIR}
  )
endif()

##################################################
# AMCL_PAILLIER Library
##################################################

if(BUILD_PAILLIER)
  foreach(level 2048 4096)
    amcl_rsa_field(BD "${level}")
    amcl_rsa_field(TFF "${level}")

    amcl_configure_file_rsa(include/config_big.h.in include/config_big_${BD}.h "${level}" amcl_paillier_GEN_HDRS)
    amcl_configure_file_rsa(include/config_ff.h.in  include/config_ff_${TFF}.h "${level}" amcl_paillier_GEN_HDRS)
    amcl_configure_file_rsa(include/big.h.in        include/big_${BD}.h        "${level}" amcl_paillier_GEN_HDRS)
    amcl_configure_file_rsa(include/ff.h.in         include/ff_${TFF}.h        "${level}" amcl_paillier_GEN_HDRS)

    amcl_configure_file_rsa(src/big.c.in src/big_${BD}.c  "${level}" amcl_paillier_GEN_SRCS)
    amcl_configure_file_rsa(src/ff.c.in  src/ff_${TFF}.c  "${level}" amcl_paillier_GEN_SRCS)
  endforeach()

  list(APPEND amcl_paillier_GEN_HDRS include/paillier.h)
  list(APPEND amcl_paillier_GEN_SRCS src/paillier.c)

  message(STATUS "Build libamcl_paillier")
  add_library(amcl_paillier
    ${amcl_paillier_GEN_SRCS}
  )
  list(APPEND AMCL_LIBRARIES amcl_paillier)

  set_target_properties(amcl_paillier PROPERTIES
    EXPORT_NAME paillier
    VERSION ${AMCL_VERSION}
    SOVERSION ${AMCL_SOVERSION}
  )

  target_include_directories(amcl_paillier PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/incldue>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
  )

  target_link_libraries(amcl_paillier PUBLIC
    amcl_core
  )

  install(TARGETS amcl_paillier
    EXPORT AMCLTargets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  )

  install(FILES
    ${amcl_paillier_GEN_HDRS}
    DESTINATION ${INSTALL_INCLUDESUBDIR}
  )
endif()

##################################################
# AMCL_RSA_*** Libraries
##################################################
foreach(level ${AMCL_RSA})
  amcl_rsa_field(BD "${level}")
  amcl_rsa_field(TFF "${level}")

  amcl_configure_file_rsa(include/config_big.h.in include/config_big_${BD}.h "${level}" amcl_rsa_${level}_GEN_HDRS)
  amcl_configure_file_rsa(include/config_ff.h.in  include/config_ff_${TFF}.h "${level}" amcl_rsa_${level}_GEN_HDRS)
  amcl_configure_file_rsa(include/big.h.in        include/big_${BD}.h        "${level}" amcl_rsa_${level}_GEN_HDRS)
  amcl_configure_file_rsa(include/ff.h.in         include/ff_${TFF}.h        "${level}" amcl_rsa_${level}_GEN_HDRS)
  amcl_configure_file_rsa(include/rsa.h.in        include/rsa_${TFF}.h       "${level}" amcl_rsa_${level}_GEN_HDRS)

  amcl_configure_file_rsa(src/big.c.in src/big_${BD}.c  "${level}" amcl_rsa_${level}_GEN_SRCS)
  amcl_configure_file_rsa(src/ff.c.in  src/ff_${TFF}.c  "${level}" amcl_rsa_${level}_GEN_SRCS)
  amcl_configure_file_rsa(src/rsa.c.in src/rsa_${TFF}.c "${level}" amcl_rsa_${level}_GEN_SRCS)

  message(STATUS "Build libamcl_rsa_${TFF}")
  add_library(amcl_rsa_${level}
    ${amcl_rsa_${level}_GEN_SRCS}
  )
  list(APPEND AMCL_LIBRARIES amcl_rsa_${TFF})

  set_target_properties(amcl_rsa_${level} PROPERTIES
    EXPORT_NAME rsa_${level}
    VERSION ${AMCL_VERSION}
    SOVERSION ${AMCL_SOVERSION}
  )

  target_include_directories(amcl_rsa_${level} PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
  )

  target_link_libraries(amcl_rsa_${level} PUBLIC
    amcl_core
  )

  install(TARGETS amcl_rsa_${level}
    EXPORT AMCLTargets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  )

  install(FILES
    ${amcl_rsa_${level}_GEN_HDRS}
    DESTINATION ${INSTALL_INCLUDESUBDIR}
  )

endforeach()

##################################################
# AMCL_CURVE_*** Libraries
##################################################
foreach(curve ${AMCL_CURVE})
  amcl_curve_field(BD "${curve}")
  amcl_curve_field(PF "${curve}")
  amcl_curve_field(TC "${curve}")
  amcl_curve_field(TF "${curve}")

  amcl_configure_file_curve(include/big.h.in          include/big_${BD}.h          "${curve}" amcl_curve_${TC}_GEN_HDRS)
  amcl_configure_file_curve(include/config_big.h.in   include/config_big_${BD}.h   "${curve}" amcl_curve_${TC}_GEN_HDRS)
  amcl_configure_file_curve(include/config_field.h.in include/config_field_${TF}.h "${curve}" amcl_curve_${TC}_GEN_HDRS)
  amcl_configure_file_curve(include/config_curve.h.in include/config_curve_${TC}.h "${curve}" amcl_curve_${TC}_GEN_HDRS)
  amcl_configure_file_curve(include/fp.h.in           include/fp_${TF}.h           "${curve}" amcl_curve_${TC}_GEN_HDRS)
  amcl_configure_file_curve(include/ecdh.h.in         include/ecdh_${TC}.h         "${curve}" amcl_curve_${TC}_GEN_HDRS)
  amcl_configure_file_curve(include/ecp.h.in          include/ecp_${TC}.h          "${curve}" amcl_curve_${TC}_GEN_HDRS)

  amcl_configure_file_curve(src/big.c.in  src/big_${BD}.c  "${curve}" amcl_curve_${TC}_GEN_SRCS)
  amcl_configure_file_curve(src/fp.c.in   src/fp_${TF}.c   "${curve}" amcl_curve_${TC}_GEN_SRCS)
  amcl_configure_file_curve(src/ecp.c.in  src/ecp_${TC}.c  "${curve}" amcl_curve_${TC}_GEN_SRCS)
  amcl_configure_file_curve(src/ecdh.c.in src/ecdh_${TC}.c "${curve}" amcl_curve_${TC}_GEN_SRCS)

  message(STATUS "Build libamcl_curve_${TC}")
  add_library(amcl_curve_${TC}
    ${amcl_curve_${TC}_GEN_SRCS}
    src/rom_curve_${TC}.c
    src/rom_field_${TF}.c
  )
  list(APPEND AMCL_LIBRARIES amcl_curve_${TC})

  set_target_properties(amcl_curve_${TC} PROPERTIES
    EXPORT_NAME curve_${TC}
    VERSION ${AMCL_VERSION}
    SOVERSION ${AMCL_SOVERSION}
  )

  target_include_directories(amcl_curve_${TC} PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
  )

  target_link_libraries(amcl_curve_${TC} PUBLIC
    amcl_core
  )

  install(TARGETS amcl_curve_${TC}
    EXPORT AMCLTargets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  )

  install(FILES
    ${amcl_curve_${TC}_GEN_HDRS}
    DESTINATION ${INSTALL_INCLUDESUBDIR}
  )
endforeach()

##################################################
# AMCL_PAIRING_*** Libraries
##################################################
foreach(curve ${AMCL_CURVE})
  amcl_curve_field(PF "${curve}")
  amcl_curve_field(TC "${curve}")
  amcl_curve_field(TF "${curve}")
  amcl_curve_field(CS "${curve}")

  if(NOT(PF STREQUAL "NOT"))
    amcl_configure_file_curve(include/fp2.h.in  include/fp2_${TF}.h  "${curve}" amcl_pairing_${TC}_GEN_HDRS)
    amcl_configure_file_curve(include/fp4.h.in  include/fp4_${TF}.h  "${curve}" amcl_pairing_${TC}_GEN_HDRS)

    amcl_configure_file_curve(src/fp2.c.in  src/fp2_${TC}.c  "${curve}" amcl_pairing_${TC}_GEN_SRCS)
    amcl_configure_file_curve(src/fp4.c.in  src/fp4_${TC}.c  "${curve}" amcl_pairing_${TC}_GEN_SRCS)

    if(CS STREQUAL "128")
      amcl_configure_file_curve(include/fp12.h.in include/fp12_${TF}.h "${curve}" amcl_pairing_${TC}_GEN_HDRS)
      amcl_configure_file_curve(include/ecp2.h.in include/ecp2_${TC}.h "${curve}" amcl_pairing_${TC}_GEN_HDRS)
      amcl_configure_file_curve(include/pair.h.in include/pair_${TC}.h "${curve}" amcl_pairing_${TC}_GEN_HDRS)

      amcl_configure_file_curve(src/fp12.c.in src/fp12_${TC}.c "${curve}" amcl_pairing_${TC}_GEN_SRCS)
      amcl_configure_file_curve(src/ecp2.c.in src/ecp2_${TC}.c "${curve}" amcl_pairing_${TC}_GEN_SRCS)
      amcl_configure_file_curve(src/pair.c.in src/pair_${TC}.c "${curve}" amcl_pairing_${TC}_GEN_SRCS)
    elseif(CS STREQUAL "192")
      amcl_configure_file_curve(include/fp8.h.in include/fp8_${TF}.h "${curve}" amcl_pairing_${TC}_GEN_HDRS)
      amcl_configure_file_curve(include/fp24.h.in include/fp24_${TF}.h "${curve}" amcl_pairing_${TC}_GEN_HDRS)
      amcl_configure_file_curve(include/ecp4.h.in include/ecp4_${TC}.h "${curve}" amcl_pairing_${TC}_GEN_HDRS)
      amcl_configure_file_curve(include/pair192.h.in include/pair192_${TC}.h "${curve}" amcl_pairing_${TC}_GEN_HDRS)

      amcl_configure_file_curve(src/fp8.c.in src/fp8_${TC}.c "${curve}" amcl_pairing_${TC}_GEN_SRCS)
      amcl_configure_file_curve(src/fp24.c.in src/fp24_${TC}.c "${curve}" amcl_pairing_${TC}_GEN_SRCS)
      amcl_configure_file_curve(src/ecp4.c.in src/ecp4_${TC}.c "${curve}" amcl_pairing_${TC}_GEN_SRCS)
      amcl_configure_file_curve(src/pair192.c.in src/pair192_${TC}.c "${curve}" amcl_pairing_${TC}_GEN_SRCS)
    elseif(CS STREQUAL "256")
      amcl_configure_file_curve(include/fp8.h.in include/fp8_${TF}.h "${curve}" amcl_pairing_${TC}_GEN_HDRS)
      amcl_configure_file_curve(include/fp16.h.in include/fp16_${TF}.h "${curve}" amcl_pairing_${TC}_GEN_HDRS)
      amcl_configure_file_curve(include/fp48.h.in include/fp48_${TF}.h "${curve}" amcl_pairing_${TC}_GEN_HDRS)
      amcl_configure_file_curve(include/ecp8.h.in include/ecp8_${TC}.h "${curve}" amcl_pairing_${TC}_GEN_HDRS)
      amcl_configure_file_curve(include/pair256.h.in include/pair256_${TC}.h "${curve}" amcl_pairing_${TC}_GEN_HDRS)

      amcl_configure_file_curve(src/fp8.c.in src/fp8_${TC}.c "${curve}" amcl_pairing_${TC}_GEN_SRCS)
      amcl_configure_file_curve(src/fp16.c.in src/fp16_${TC}.c "${curve}" amcl_pairing_${TC}_GEN_SRCS)
      amcl_configure_file_curve(src/fp48.c.in src/fp48_${TC}.c "${curve}" amcl_pairing_${TC}_GEN_SRCS)
      amcl_configure_file_curve(src/ecp8.c.in src/ecp8_${TC}.c "${curve}" amcl_pairing_${TC}_GEN_SRCS)
      amcl_configure_file_curve(src/pair256.c.in src/pair256_${TC}.c "${curve}" amcl_pairing_${TC}_GEN_SRCS)
    endif(CS STREQUAL "128")

    message(STATUS "Build libamcl_pairing_${TC}")
    add_library(amcl_pairing_${TC}
      ${amcl_pairing_${TC}_GEN_SRCS}
    )
    list(APPEND AMCL_LIBRARIES amcl_pairing_${TC})

    set_target_properties(amcl_pairing_${TC} PROPERTIES
      EXPORT_NAME pairing_${TC}
      VERSION ${AMCL_VERSION}
      SOVERSION ${AMCL_SOVERSION}
    )

    target_include_directories(amcl_pairing_${TC} PUBLIC
      $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
      $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
      $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    )

    target_link_libraries(amcl_pairing_${TC} PUBLIC
      amcl_curve_${TC}
    )

    install(TARGETS amcl_pairing_${TC}
      EXPORT AMCLTargets
      RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
      LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
      ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    )

    install(FILES
      ${amcl_pairing_${TC}_GEN_HDRS}
      DESTINATION ${INSTALL_INCLUDESUBDIR}
    )
  endif(NOT(PF STREQUAL "NOT"))
endforeach()

##################################################
# AMCL_MPIN_*** Libraries
##################################################
if(BUILD_MPIN)
  foreach(curve ${AMCL_CURVE})
    amcl_curve_field(TC "${curve}")
    amcl_curve_field(CS "${curve}")

    if(TARGET amcl_pairing_${TC})
      if(CS STREQUAL "128")
        amcl_configure_file_curve(include/mpin.h.in include/mpin_${TC}.h "${curve}" amcl_mpin_${TC}_GEN_HDRS)
        amcl_configure_file_curve(src/mpin.c.in     src/mpin_${TC}.c     "${curve}" amcl_mpin_${TC}_GEN_SRCS)
      else(CS STREQUAL "128")
        amcl_configure_file_curve(include/mpin${CS}.h.in include/mpin${CS}_${TC}.h "${curve}" amcl_mpin_${TC}_GEN_HDRS)
        amcl_configure_file_curve(src/mpin${CS}.c.in     src/mpin${CS}_${TC}.c     "${curve}" amcl_mpin_${TC}_GEN_SRCS)
      endif(CS STREQUAL "128")

      message(STATUS "Build libamcl_mpin_${TC}")
      add_library(amcl_mpin_${TC}
        ${amcl_mpin_${TC}_GEN_SRCS}
      )
      list(APPEND AMCL_LIBRARIES amcl_mpin_${TC})

      set_target_properties(amcl_mpin_${TC} PROPERTIES
        EXPORT_NAME mpin_${TC}
        VERSION ${AMCL_VERSION}
        SOVERSION ${AMCL_SOVERSION}
      )

      target_include_directories(amcl_mpin_${TC} PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
      )

      target_link_libraries(amcl_mpin_${TC} PUBLIC
        amcl_pairing_${TC}
      )

      install(TARGETS amcl_mpin_${TC}
        EXPORT AMCLTargets
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
      )

      install(FILES
        ${amcl_mpin_${TC}_GEN_HDRS}
        DESTINATION ${INSTALL_INCLUDESUBDIR}
      )
    endif()
  endforeach()
endif()

##################################################
# AMCL_WCC_*** Libraries
##################################################
if(BUILD_WCC)
  foreach(curve ${AMCL_CURVE})
    amcl_curve_field(TC "${curve}")
    amcl_curve_field(CS "${curve}")

    if(TARGET amcl_pairing_${TC})
      if(CS STREQUAL "128")
        amcl_configure_file_curve(include/wcc.h.in include/wcc_${TC}.h "${curve}" amcl_wcc_${TC}_GEN_HDRS)
        amcl_configure_file_curve(src/wcc.c.in     src/wcc_${TC}.c     "${curve}" amcl_wcc_${TC}_GEN_SRCS)
      else(CS STREQUAL "128")
        amcl_configure_file_curve(include/wcc${CS}.h.in include/wcc${CS}_${TC}.h "${curve}" amcl_wcc_${TC}_GEN_HDRS)
        amcl_configure_file_curve(src/wcc${CS}.c.in     src/wcc${CS}_${TC}.c     "${curve}" amcl_wcc_${TC}_GEN_SRCS)
      endif(CS STREQUAL "128")

      message(STATUS "Build libamcl_wcc_${TC}")
      add_library(amcl_wcc_${TC}
        ${amcl_wcc_${TC}_GEN_SRCS}
      )
      list(APPEND AMCL_LIBRARIES amcl_wcc_${TC})

      set_target_properties(amcl_wcc_${TC} PROPERTIES
        EXPORT_NAME wcc_${TC}
        VERSION ${AMCL_VERSION}
        SOVERSION ${AMCL_SOVERSION}
      )

      target_include_directories(amcl_wcc_${TC} PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
      )

      target_link_libraries(amcl_wcc_${TC} PUBLIC
        amcl_pairing_${TC}
      )

      install(TARGETS amcl_wcc_${TC}
        EXPORT AMCLTargets
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
      )

      install(FILES
        ${amcl_wcc_${TC}_GEN_HDRS}
        DESTINATION ${INSTALL_INCLUDESUBDIR}
      )
    endif()
  endforeach()
endif()

##################################################
# AMCL_BLS_*** Libraries
##################################################
if(BUILD_BLS)
  foreach(curve ${AMCL_CURVE})
    amcl_curve_field(TC "${curve}")
    amcl_curve_field(CS "${curve}")

    if(TARGET amcl_pairing_${TC})
      if(CS STREQUAL "128")
        amcl_configure_file_curve(include/bls.h.in include/bls_${TC}.h "${curve}" amcl_bls_${TC}_GEN_HDRS)
        amcl_configure_file_curve(src/bls.c.in     src/bls_${TC}.c     "${curve}" amcl_bls_${TC}_GEN_SRCS)
      else(CS STREQUAL "128")
        amcl_configure_file_curve(include/bls${CS}.h.in include/bls${CS}_${TC}.h "${curve}" amcl_bls_${TC}_GEN_HDRS)
        amcl_configure_file_curve(src/bls${CS}.c.in     src/bls${CS}_${TC}.c     "${curve}" amcl_bls_${TC}_GEN_SRCS)
      endif(CS STREQUAL "128")

      message(STATUS "Build libamcl_bls_${TC}")
      add_library(amcl_bls_${TC}
        ${amcl_bls_${TC}_GEN_SRCS}
      )
      list(APPEND AMCL_LIBRARIES amcl_bls_${TC})

      set_target_properties(amcl_bls_${TC} PROPERTIES
        EXPORT_NAME bls_${TC}
        VERSION ${AMCL_VERSION}
        SOVERSION ${AMCL_SOVERSION}
      )

      target_include_directories(amcl_bls_${TC} PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
      )

      target_link_libraries(amcl_bls_${TC} PUBLIC
        amcl_pairing_${TC}
      )

      install(TARGETS amcl_bls_${TC}
        EXPORT AMCLTargets
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
      )

      install(FILES
        ${amcl_bls_${TC}_GEN_HDRS}
        DESTINATION ${INSTALL_INCLUDESUBDIR}
      )
    endif()
  endforeach()
endif()

##################################################
# pkgconfig
##################################################
foreach(lib ${AMCL_LIBRARIES})
  set(AMCL_PRIVATE_LIBS "${AMCL_PRIVATE_LIBS} -l${lib}")
endforeach()
configure_file(amcl.pc.in amcl.pc @ONLY)
install(FILES
  ${CMAKE_CURRENT_BINARY_DIR}/amcl.pc
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig
)

##################################################
# CMake export
##################################################
set(INSTALL_CONFIGDIR ${CMAKE_INSTALL_LIBDIR}/cmake/amcl)

install(EXPORT AMCLTargets
  FILE AMCLTargets.cmake
  NAMESPACE AMCL::
  DESTINATION ${INSTALL_CONFIGDIR}
)

include(CMakePackageConfigHelpers)
write_basic_package_version_file(
  ${CMAKE_CURRENT_BINARY_DIR}/AMCLConfigVersion.cmake
  VERSION ${AMCL_VERSION}
  COMPATIBILITY SameMajorVersion
)

configure_package_config_file(${CMAKE_CURRENT_SOURCE_DIR}/AMCLConfig.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/AMCLConfig.cmake
  INSTALL_DESTINATION ${INSTALL_CONFIGDIR}
)

install(FILES
  ${CMAKE_CURRENT_BINARY_DIR}/AMCLConfig.cmake
  ${CMAKE_CURRENT_BINARY_DIR}/AMCLConfigVersion.cmake
  DESTINATION ${INSTALL_CONFIGDIR}
)

##################################################
# Uninstall Target
##################################################
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
    IMMEDIATE @ONLY)

add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)

##################################################
# Add subdirectories
##################################################
if(BUILD_BENCHMARKS)
  message(STATUS "Build benchmarks")
  add_subdirectory(benchmark)
endif()

if(BUILD_DOCS)
  message(STATUS "Build docs")
  add_subdirectory(doc)
endif()

if(BUILD_EXAMPLES)
  message(STATUS "Build examples")
  add_subdirectory(examples)
endif()

if(BUILD_PYTHON)
  message(STATUS "Build Python wrappers")
  add_subdirectory(python)
endif()

if(BUILD_TESTING)
  message(STATUS "Build tests")
  add_subdirectory(test)
endif()

include(CPackConfig.cmake)
