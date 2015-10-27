//
//  ZTAudioBuffer.h
//  ZTAudioPlay
//
//  Created by 谢展图 on 15/7/26.
//  Copyright (c) 2015年 spice. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import "ZTAudioParsedData.h"

@interface ZTAudioBuffer : NSObject

+ (instancetype)buffer;

- (void)enqueueData:(ZTAudioParsedData *)data;
- (void)enqueueFromDataArray:(NSArray *)dataArray;

- (BOOL)hasData;
- (UInt32)bufferedSize;

//descriptions needs free
- (NSData *)dequeueDataWithSize:(UInt32)requestSize packetCount:(UInt32 *)packetCount descriptions:(AudioStreamPacketDescription **)descriptions;

- (void)clean;

@end
