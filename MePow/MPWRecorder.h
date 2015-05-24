//
//  MPWRecorder.h
//  MePow
//
//  Created by WeeTom on 15/5/24.
//  Copyright (c) 2015年 Mingdao. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface MPWRecorder : AVAudioRecorder
@property (strong, nonatomic) PFObject *meeting;
@property (assign, nonatomic) float recordLength;
@property (strong, nonatomic) UIProgressView *pv;
@property (strong, nonatomic) UILabel *label;

+ (MPWRecorder *)reocorderForMeeting:(PFObject *)meeting;
@end
