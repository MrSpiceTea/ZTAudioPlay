//
//  ZTHTTPSource.h
//  ZTAudioPlay
//
//  Created by 谢展图 on 15/7/25.
//  Copyright (c) 2015年 spice. All rights reserved.
//

#import "ZTDataSource.h"
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudioTypes.h>
@interface ZTHTTPSource : NSObject<ZTDataSource>

@property (readonly) SInt64 position;
@property (readonly) SInt64 length;
@property (nonatomic,assign,readonly) AudioFileTypeID fileType;
@property (nonatomic,assign,readonly) unsigned long long fileSize;
@property (nonatomic,assign,readonly) unsigned long long offset;
@property (nonatomic,strong) NSMutableData *data;
@property (nonatomic,strong) NSFileHandle *fileHandler;
@property (nonatomic,strong) NSString *filePath;
@property (nonatomic,strong) NSURL *url;


@end
