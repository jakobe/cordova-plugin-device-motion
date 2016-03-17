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

#import <CoreMotion/CoreMotion.h>
#import "CDVAccelerometer.h"

@interface CDVAccelerometer () {}
@property (readwrite, assign) BOOL isRunning;
@property (readwrite, assign) BOOL haveReturnedResult;
@property (readwrite, strong) CMMotionManager* motionManager;
@property (readwrite, assign) double x;
@property (readwrite, assign) double y;
@property (readwrite, assign) double z;
@property (readwrite, assign) double userAccelerationX;
@property (readwrite, assign) double userAccelerationY;
@property (readwrite, assign) double userAccelerationZ;
@property (readwrite, assign) double rotationX;
@property (readwrite, assign) double rotationY;
@property (readwrite, assign) double rotationZ;
@property (readwrite, assign) double yaw;
@property (readwrite, assign) double pitch;
@property (readwrite, assign) double roll;
@property (readwrite, assign) NSTimeInterval timestamp;
@end

@implementation CDVAccelerometer

@synthesize callbackId, isRunning,x,y,z,userAccelerationX,userAccelerationY,userAccelerationZ,rotationX,rotationY,rotationZ,yaw,pitch,roll,timestamp;

// defaults to 10 msec
#define kDeviceMotionInterval 10
// g constant: -9.81 m/s^2
#define kGravitationalConstant -9.81

- (CDVAccelerometer*)init
{
    self = [super init];
    if (self) {
        self.x = 0;
        self.y = 0;
        self.z = 0;
        self.userAccelerationX = 0;
        self.userAccelerationY = 0;
        self.userAccelerationZ = 0;
        self.rotationX = 0;
        self.rotationY = 0;
        self.rotationZ = 0;
        self.yaw = 0;
        self.pitch = 0;
        self.roll = 0;
        self.timestamp = 0;
        self.callbackId = nil;
        self.isRunning = NO;
        self.haveReturnedResult = YES;
        self.motionManager = nil;
    }
    return self;
}

- (void)dealloc
{
    [self stop:nil];
}

- (void)start:(CDVInvokedUrlCommand*)command
{
    self.haveReturnedResult = NO;
    self.callbackId = command.callbackId;

    if (!self.motionManager)
    {
        self.motionManager = [[CMMotionManager alloc] init];
    }

    if ([self.motionManager isDeviceMotionAvailable] == YES) {
        // Assign the update interval to the motion manager and start updates
        [self.motionManager setDeviceMotionUpdateInterval:kDeviceMotionInterval/1000];  // expected in seconds
        __weak CDVAccelerometer* weakSelf = self;
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
            weakSelf.x = motion.gravity.x + motion.userAcceleration.x;
            weakSelf.y = motion.gravity.y + motion.userAcceleration.y;
            weakSelf.z = motion.gravity.z + motion.userAcceleration.z;
            weakSelf.userAccelerationX = motion.userAcceleration.x;
            weakSelf.userAccelerationY = motion.userAcceleration.y;
            weakSelf.userAccelerationZ = motion.userAcceleration.z;
            weakSelf.rotationX = motion.rotationRate.x;
            weakSelf.rotationY = motion.rotationRate.y;
            weakSelf.rotationZ = motion.rotationRate.z;
            weakSelf.yaw = motion.attitude.yaw;
            weakSelf.pitch = motion.attitude.pitch;
            weakSelf.roll = motion.attitude.roll;
            weakSelf.timestamp = ([[NSDate date] timeIntervalSince1970] * 1000);
            [weakSelf returnAccelInfo];
        }];

        if (!self.isRunning) {
            self.isRunning = YES;
        }
    }
    else {

        NSLog(@"Running in Simulator? All gyro tests will fail.");
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"Error. Accelerometer Not Available."];

        [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
    }

}

- (void)onReset
{
    [self stop:nil];
}

- (void)stop:(CDVInvokedUrlCommand*)command
{
    if ([self.motionManager isAccelerometerAvailable] == YES) {
        if (self.haveReturnedResult == NO){
            // block has not fired before stop was called, return whatever result we currently have
            [self returnAccelInfo];
        }
        [self.motionManager stopAccelerometerUpdates];
    }
    self.isRunning = NO;
}

- (void)returnAccelInfo
{
    // Create an acceleration object
    NSMutableDictionary* accelProps = [NSMutableDictionary dictionaryWithCapacity:13];

    [accelProps setValue:[NSNumber numberWithDouble:self.x * kGravitationalConstant] forKey:@"x"];
    [accelProps setValue:[NSNumber numberWithDouble:self.y * kGravitationalConstant] forKey:@"y"];
    [accelProps setValue:[NSNumber numberWithDouble:self.z * kGravitationalConstant] forKey:@"z"];
    [accelProps setValue:[NSNumber numberWithDouble:self.userAccelerationX * kGravitationalConstant] forKey:@"userAccelerationX"];
    [accelProps setValue:[NSNumber numberWithDouble:self.userAccelerationY * kGravitationalConstant] forKey:@"userAccelerationY"];
    [accelProps setValue:[NSNumber numberWithDouble:self.userAccelerationZ * kGravitationalConstant] forKey:@"userAccelerationZ"];
    [accelProps setValue:[NSNumber numberWithDouble:self.rotationX] forKey:@"rotationX"];
    [accelProps setValue:[NSNumber numberWithDouble:self.rotationY] forKey:@"rotationY"];
    [accelProps setValue:[NSNumber numberWithDouble:self.rotationZ] forKey:@"rotationZ"];
    [accelProps setValue:[NSNumber numberWithDouble:self.yaw] forKey:@"yaw"];
    [accelProps setValue:[NSNumber numberWithDouble:self.pitch] forKey:@"pitch"];
    [accelProps setValue:[NSNumber numberWithDouble:self.roll] forKey:@"roll"];
    [accelProps setValue:[NSNumber numberWithDouble:self.timestamp] forKey:@"timestamp"];

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:accelProps];
    [result setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
    self.haveReturnedResult = YES;
}

// TODO: Consider using filtering to isolate instantaneous data vs. gravity data -jm

/*
 #define kFilteringFactor 0.1

 // Use a basic low-pass filter to keep only the gravity component of each axis.
 grav_accelX = (acceleration.x * kFilteringFactor) + ( grav_accelX * (1.0 - kFilteringFactor));
 grav_accelY = (acceleration.y * kFilteringFactor) + ( grav_accelY * (1.0 - kFilteringFactor));
 grav_accelZ = (acceleration.z * kFilteringFactor) + ( grav_accelZ * (1.0 - kFilteringFactor));

 // Subtract the low-pass value from the current value to get a simplified high-pass filter
 instant_accelX = acceleration.x - ( (acceleration.x * kFilteringFactor) + (instant_accelX * (1.0 - kFilteringFactor)) );
 instant_accelY = acceleration.y - ( (acceleration.y * kFilteringFactor) + (instant_accelY * (1.0 - kFilteringFactor)) );
 instant_accelZ = acceleration.z - ( (acceleration.z * kFilteringFactor) + (instant_accelZ * (1.0 - kFilteringFactor)) );


 */
@end
