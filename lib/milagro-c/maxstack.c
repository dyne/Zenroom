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

/*
	How to determine maximum stack usage
	1. Compile this file *with no optimization*, for example gcc -c maxstack.c
	2. Rename your main() function to mymain()
	3. Compile with normal level of optimization, linking to maxstack.o for example gcc maxstack.o -O3 myprogram.c -o myprogam
	4. Execute myprogram
	5. Program runs, at end prints out maximum stack usage

	Caveat Code!
	Mike Scott October 2014
*/

#include <stdio.h>

#define MAXSTACK 65536  /* greater than likely stack requirement */

extern void mymain();

void start()
{
	char stack[MAXSTACK];
	int i;
	for (i=0;i<MAXSTACK;i++) stack[i]=0x55;
}

void finish()
{
	char stack[MAXSTACK];
	int i;
	for (i=0;i<MAXSTACK;i++)
		if (stack[i]!=0x55) break;
	printf("Max Stack usage = %d\n",MAXSTACK-i);
}

int main()
{
 start();

 mymain();

 finish();
 return 0;
}
