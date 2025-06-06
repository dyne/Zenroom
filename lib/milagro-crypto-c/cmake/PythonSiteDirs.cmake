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

cmake_minimum_required(VERSION 3.5)

execute_process(COMMAND
  python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())"
  OUTPUT_VARIABLE PYTHON3_SITE_PACKAGES
  OUTPUT_STRIP_TRAILING_WHITESPACE
)

execute_process(COMMAND
  python3 -c "from distutils.sysconfig import get_python_lib; from os.path import dirname; print(dirname(get_python_lib()))"
  OUTPUT_VARIABLE PYTHON3_SITE_LIB
)
