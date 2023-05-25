/**
 * DECODE App – A mobile app to control your personal data
 *
 * Copyright (C) 2019 – DRIBIA Data Research S.L.
 *
 * DECODE App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * DECODE App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * email: info@dribia.com
 */

#import "Zenroom.h"
#import <React/RCTLog.h>
#import "zenroomInternal.h"

@implementation Zenroom

RCT_EXPORT_MODULE();


RCT_EXPORT_METHOD(execute:(NSString *)contract data:(NSString *)data key:(NSString*)key withResolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    
    char *c = [contract UTF8String];
    char *d = [data UTF8String];
    char *k = [key UTF8String];
    
    size_t outputSize = 1024 * 128;
    char *z_output = (char*)malloc(outputSize * sizeof(char));
    size_t errorSize = 1024 * 128;
    char *z_error = (char*)malloc(errorSize * sizeof(char));
    
    zenroom_exec_tobuf(c, NULL, k, d, 3, z_output, outputSize, z_error, errorSize);
    
    NSLog(@"output: %s", z_output);
    NSLog(@"error: %s", z_error);
    
    
    resolve([NSString stringWithUTF8String: z_output]);
    
}

// RCT_EXPORT_MODULE(Zenroom);

@end

