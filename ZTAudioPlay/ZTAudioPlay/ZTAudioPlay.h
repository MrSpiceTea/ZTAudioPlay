//
//  ZTAudioPlay.h
//  ZTAudioPlay
//
//  Created by 谢展图 on 15/7/25.
//  Copyright (c) 2015年 spice. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioFile.h>

#import "ZTDataSource.h"
#import "ZTLocalSource.h"
#import "ZTHTTPSource.h"
#import "ZTFlacSource.h"

typedef NS_ENUM (NSInteger, ZTPlaybackState) {
    ZTPlaybackStateUnknown,
    ZTPlaybackStateBuffering,
    ZTPlaybackStatePlaying,
    ZTPlaybackStatePause,
    ZTPlaybackStateFlushing,
    ZTPlaybackStateStop,
    ZTPlaybackStateFailed,
};

@interface ZTAudioPlay : NSObject

@property (nonatomic,readonly) BOOL isPlayingOrWaiting;
@property (nonatomic,assign)ZTPlaybackState playState;
@property (nonatomic,strong)id<ZTDataSource> dataSource;

@property (nonatomic,assign) NSTimeInterval progress;
@property (nonatomic,readonly) NSTimeInterval duration;

- (instancetype)initWithurl:(NSURL *)url;

- (void)play;
- (void)pause;
- (void)stop;

@end
