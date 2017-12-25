/*
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
*/

/* Use with Visual Studio Compiler for building Shared libraries */
#ifndef _DLLDEFINES_H_
#define _DLLDEFINES_H_

/* Cmake will define sok_EXPORTS and mpin_EXPORTS on Windows when it
configures to build a shared library. If you are going to use
another build system on windows or create the visual studio
projects by hand you need to define sok_EXPORTS and mpin_EXPORTS when
building a DLL on windows. */
/* #define sok_EXPORTS */
/* #define mpin_EXPORTS */


#if defined (_MSC_VER)

 #define DLL_EXPORT extern
/* This code does not work with cl */
/*  #if defined(sok_EXPORTS) || defined(mpin_EXPORTS) */
/*    #define  DLL_EXPORT __declspec(dllexport) */
/*  #else */
/*    #define  DLL_EXPORT __declspec(dllimport) */
/*  #endif /\* sok_EXPORTS || mpin_EXPORTS *\/ */

#else /* defined (_WIN32) */

 #define DLL_EXPORT extern

#endif

#endif /* _DLLDEFINES_H_ */
