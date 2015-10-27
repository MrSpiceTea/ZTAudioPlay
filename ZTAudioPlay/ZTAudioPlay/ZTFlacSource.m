//
//  ZTFlacSource.m
//  ZTAudioPlay
//
//  Created by 谢展图 on 15/7/25.
//  Copyright (c) 2015年 spice. All rights reserved.
//

#import "ZTFlacSource.h"
#import "ZTFlacDecoder.h"
#define CHUNK_SIZE 16 * 1024   //原值：16*1024
//#define CHUNK_SIZE 4 * 1024   //原值：16*1024

#define BUFFER_SIZE 128 * 1024  //原值：256*1024

@interface ZTFlacSource (){
     void *inputBuffer;
     int bytesPerFrame;
     int amountInBuffer ;
     int framesRead ;
    
}
@property (retain, nonatomic) ZTFlacDecoder *decoder;
@end

@implementation ZTFlacSource

+ (dispatch_queue_t)lock_queue {
    static dispatch_queue_t _lock_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _lock_queue = dispatch_queue_create("com.flacsource.lock",
                                            DISPATCH_QUEUE_SERIAL);
    });
    return _lock_queue;
}


- (id)initWithUrl:(NSURL *)url{
    if (self = [super init])
    {
        self.url = url;
        inputBuffer = malloc(CHUNK_SIZE);
        self.data = [NSMutableData data];
        
        [self openfile];
        
        _fileSize = 1;
        _fileType = 0;
        self.decoder = [[ZTFlacDecoder alloc]init];
        [self.decoder open:self];
        
        amountInBuffer = 0;
        framesRead = 0;
        [self readDecoderData];
    
    
    }
    return self;
}

-(void) seekToOffset:(SInt64)offset{
    
}

- (void)closeFile{

    [self closeFd];
}

//FlacParsedData
- (NSData *)readDataOfLength:(long)length
{
//    [self readDecoderData];
    
//    NSData * readdata = [NSData]
    return self.data;
    
}

- (void)readDecoderData{
    int channels = [[self.decoder.properties objectForKey:@"channels"] intValue];
    int bitsPerSample = [[_decoder.properties objectForKey:@"bitsPerSample"] intValue];
    bytesPerFrame = (bitsPerSample/8) * channels;
    
    do {
        if (_data.length >= BUFFER_SIZE) {
            framesRead = 1;
            break;
        }
        
        
        int framesToRead = CHUNK_SIZE/bytesPerFrame;
        framesRead = [_decoder readAudio:inputBuffer frames:framesToRead];
        
        amountInBuffer = (framesRead * bytesPerFrame);
        dispatch_sync([ZTFlacSource lock_queue], ^{
            [_data appendBytes:inputBuffer length:amountInBuffer];
            NSLog(@"%lu",(unsigned long)_data.length);
        });
    } while (framesRead > 0);
}

- (void)seekDataOffset:(unsigned long long)offset{

}

- (BOOL)isOpenData{
    return self.fd;
}


- (BOOL)seekable {
    return YES;
}


#pragma mark
- (void) openfile{
	_fd = fopen([[self.url path] UTF8String], "r");
}

- (int)read:(void *)buffer amount:(int)amount {
    return fread(buffer, 1, amount, _fd);
}

- (void)closeFd {
    if (_fd) {
        fclose(_fd);
        _fd = NULL;
    }
}

- (BOOL)seek:(long)position whence:(int)whence {
    return (fseek(_fd, position, whence) == 0);
}

- (long)tell {
    return ftell(_fd);
}

- (long)size {
    long curpos = ftell(_fd);
    fseek (_fd, 0, SEEK_END);
    long size = ftell(_fd);
    fseek(_fd, curpos, SEEK_SET);
    return size;
}


@end
