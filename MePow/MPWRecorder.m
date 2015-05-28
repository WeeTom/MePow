//
//  MPWRecorder.m
//  MePow
//
//  Created by WeeTom on 15/5/24.
//  Copyright (c) 2015年 Mingdao. All rights reserved.
//

#import "MPWRecorder.h"

#define WAVE_UPDATE_FREQUENCY   0.05

@interface MPWRecorder ()
@property (strong, nonatomic) NSTimer *timer;
@end

@implementation MPWRecorder
+ (MPWRecorder *)reocorderForMeeting:(PFObject *)meeting
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&err];
    [audioSession setActive:YES error:&err];
    BOOL audioHWAvailable = audioSession.inputAvailable;
    if (! audioHWAvailable) {
        NSLog(@"audio unavailable");
        return nil;
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat: @"yyyy_MM_dd_HH_mm_ss_SSS"];
    NSString *timeDesc = [formatter stringFromDate:[NSDate date]];
    
    NSURL *url = [NSURL fileURLWithPath:[[[MPWGlobal recordPathForMeeting:meeting] stringByAppendingPathComponent:timeDesc] stringByAppendingPathExtension:@"pcm"]];
    
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    // You can change the settings for the voice quality
    [recordSetting setValue :[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:16000.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
    
    NSError *error = nil;

    MPWRecorder *recorder = [[MPWRecorder alloc] initWithURL:url settings:recordSetting error:&error];
    recorder.meeting = meeting;
    recorder.meteringEnabled = YES;
    
    if (error) {
        return nil;
    }
    
    return recorder;
}

- (BOOL)record
{
    [self.timer invalidate];
    self.timer = nil;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:WAVE_UPDATE_FREQUENCY target:self selector:@selector(updateMeters) userInfo:nil repeats:YES];
    return [super record];
}

- (void)stop
{
    [self.timer invalidate];
    self.timer = nil;
    [super stop];
}

- (void)updateMeters {
    [super updateMeters];
    
    self.recordLength += WAVE_UPDATE_FREQUENCY;
    
    float avgPower = [self averagePowerForChannel:0];
    NSLog(@"%.2f", avgPower);
    self.pv.progress = (avgPower + 160)/160.0;
    
    [self.label setText:[NSString stringWithFormat:@"Recording %.2f", self.recordLength]];
}
@end
