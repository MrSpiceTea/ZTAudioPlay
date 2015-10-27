//
//  ZTLocalSource.m
//  ZTAudioPlay
//
//  Created by 谢展图 on 15/7/25.
//  Copyright (c) 2015年 spice. All rights reserved.
//

#import "ZTLocalSource.h"

@interface ZTLocalSource()

@end

@implementation ZTLocalSource

- (id)initWithUrl:(NSURL *)url{
    if (self = [super init])
    {
        self.url = url;
        self.filePath = url.path;
        _fileHandler = [NSFileHandle fileHandleForReadingAtPath:_filePath];
        _fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:_filePath error:nil] fileSize];

    }
    return self;
}

-(void) seekToOffset:(SInt64)offset{
    
}

- (void)closeFile{
    [self.fileHandler closeFile];
}

- (NSData *)readDataOfLength:(long)length
{
    return [self.fileHandler readDataOfLength:length];
}

- (void)seekDataOffset:(unsigned long long)offset{
    [self.fileHandler seekToFileOffset:offset];
}

- (BOOL)isOpenData{
    return self.fileHandler;
}

@end
