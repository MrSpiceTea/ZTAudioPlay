//
//  ZTAudioFileStream.h
//  ZTAudioPlay
//
//  Created by 谢展图 on 15/7/25.
//  Copyright (c) 2015年 spice. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>



@class ZTAudioFileStream;
@protocol ZTAudioFileStreamDelegate <NSObject>
@required
- (void)audioFileStream:(ZTAudioFileStream *)audioFileStream audioDataParsed:(NSArray *)audioData;
@optional
- (void)audioFileStreamReadyToProducePackets:(ZTAudioFileStream *)audioFileStream;
@end

@interface ZTAudioFileStream : NSObject

@property (nonatomic,assign,readonly) AudioFileTypeID fileType;
@property (nonatomic,assign,readonly) BOOL available;
@property (nonatomic,assign,readonly) BOOL readyToProducePackets;
@property (nonatomic,weak) id<ZTAudioFileStreamDelegate> delegate;

@property (nonatomic,assign,readonly) AudioStreamBasicDescription format;
@property (nonatomic,assign,readonly) unsigned long long fileSize;
@property (nonatomic,assign,readonly) NSTimeInterval duration;
@property (nonatomic,assign,readonly) UInt32 bitRate;
@property (nonatomic,assign,readonly) UInt32 maxPacketSize;
@property (nonatomic,assign,readonly) UInt64 audioDataByteCount;

- (instancetype)initWithFileType:(AudioFileTypeID)fileType fileSize:(unsigned long long)fileSize error:(NSError **)error;

- (BOOL)parseData:(NSData *)data error:(NSError **)error;

- (SInt64)seekToTime:(NSTimeInterval *)time;

- (NSData *)fetchMagicCookie;

- (void)close;

@end
