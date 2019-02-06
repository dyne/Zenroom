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

function(DETERMINE_WORD_SIZE word_size)

# Check if 64-bit
  try_compile(COMPILE_SUCCESS "${CMAKE_CURRENT_BINARY_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/determine_word_size/check_64.c")

  if(COMPILE_SUCCESS)
    set(${word_size} 64 PARENT_SCOPE)
    return()
  endif()

# Check if 32-bit
  try_compile(COMPILE_SUCCESS "${CMAKE_CURRENT_BINARY_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/determine_word_size/check_32.c")

  if(COMPILE_SUCCESS)
    set(${word_size} 32 PARENT_SCOPE)
    return()
  endif()

# Check if 16-bit
  try_compile(COMPILE_SUCCESS "${CMAKE_CURRENT_BINARY_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/determine_word_size/check_16.c")

  if(COMPILE_SUCCESS)
    set(${word_size} 16 PARENT_SCOPE)
    return()
  endif()

endfunction()
