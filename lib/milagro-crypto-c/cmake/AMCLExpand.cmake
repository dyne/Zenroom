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

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR})
include(AMCLParameters)

# Copies a file <source> to file <target> and substitutes variable
# values referenced as @VAR@, WWW, XXX, YYY, and ZZZ in the file
# content.  These variables must be set in the caller's scope.
#
# If <source> is a relative path it is evaluated with respect to the
# current source directory.  If <target> is a relative path it is
# evaluated with respect to the current binary directory.
#
# The full path of the target file is appended to <targets_list>.
#
macro(__amcl_configure_file source target targets_list)
  get_filename_component(target_full "${target}" ABSOLUTE
    BASE_DIR "${CMAKE_CURRENT_BINARY_DIR}")
  set(AMCL_CHUNK ${WORD_SIZE})
  set(WL ${WORD_SIZE})

  configure_file("${source}" "${target_full}" @ONLY)
  file(READ "${target_full}" temp)
  string(REPLACE WWW "${TFF}" temp "${temp}")
  string(REPLACE XXX "${BD}"  temp "${temp}")
  string(REPLACE YYY "${TF}"  temp "${temp}")
  string(REPLACE ZZZ "${TC}"  temp "${temp}")
  file(WRITE "${target_full}" "${temp}")

  list(APPEND "${targets_list}" "${target_full}")
  set("${targets_list}" "${${targets_list}}" PARENT_SCOPE)
endmacro()

######################################################################
# Expands an AMCL template file. No RSA or curve params are set.
function(amcl_configure_file_core source target targets_list)
  __amcl_configure_file("${source}" "${target}" "${targets_list}")
endfunction()

# Expands an AMCL template file, including the RSA params for the
# specified level.
function(amcl_configure_file_rsa source target level targets_list)
  amcl_load_rsa(${level})
  __amcl_configure_file("${source}" "${target}" "${targets_list}")
endfunction()

# Expands an AMCL template file, including the curve params for the
# specified curve.
function(amcl_configure_file_curve source target curve targets_list)
  amcl_load_curve(${curve})
  __amcl_configure_file("${source}" "${target}" "${targets_list}")
endfunction()

# Expands an AMCL template file, including the rsa and curve params
# for the specified level and curve.
function(amcl_configure_file_rsa_curve source target level curve targets_list)
  amcl_load_rsa(${level})
  amcl_load_curve(${curve})
  __amcl_configure_file("${source}" "${target}" "${targets_list}")
endfunction()

######################################################################
# Generates the SC variable (#defined of supported curves) for
# version.h.in
function(amcl_generate_SC SC)
  set(text "")
  
  foreach(curve ${AMCL_CURVE})
    amcl_curve_field(TC ${curve})
    set(text "${text}#define ${TC}_VER\n")
  endforeach()

  set("${SC}" "${text}" PARENT_SCOPE)
endfunction()

# Generates the RSL variable (#defines of supported RSA security
# level) for version.h.in
function(amcl_generate_RSL RSL)
  set(${text} "")

  foreach(level ${AMCL_RSA})
    amcl_rsa_field(TFF ${level})
    set(text "${text}#define RSA_SECURITY_LEVEL_${TFF}_VER\n")
  endforeach()

  set("${RSL}" "${text}" PARENT_SCOPE)
endfunction()
