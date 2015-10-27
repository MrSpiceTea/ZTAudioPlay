//
//  ZTAudioPlay.m
//  ZTAudioPlay
//
//  Created by 谢展图 on 15/7/25.
//  Copyright (c) 2015年 spice. All rights reserved.
//

#import "ZTAudioPlay.h"

#import "MCAudioSession.h"
#import "ZTAudioParsedData.h"
#import "ZTAudioFileStream.h"
#import "ZTAudioFile.h"
#import "ZTAudioBuffer.h"
#import "ZTAudioOutputQueue.h"
#import "ZTDecoder.h"

#import <pthread.h>

#define CHUNK_SIZE 4 * 1024   //原值：16*1024
// deault buffer size
#define BUFFER_SIZE 128 * 1024  //原值：256*1024

@interface ZTAudioPlay ()<ZTAudioFileStreamDelegate>{
    @private
    NSThread *_thread;
    pthread_mutex_t _mutex;
    pthread_cond_t _cond;
    
    
    unsigned long long _fileSize;
    unsigned long long _offset;
//    NSFileHandle *_fileHandler;
    UInt32 _bufferSize;
    
    
    BOOL _started;
    BOOL _pauseRequired;
    BOOL _stopRequired;
    BOOL _pausedByInterrupt;
    BOOL _usingAudioFile;
    
    BOOL _seekRequired;
    NSTimeInterval _seekTime;
    NSTimeInterval _timingOffset;
    
    ZTAudioFileStream *_decoder;
    ZTAudioFileStream *_audioFileStream;
    ZTAudioFile *_audioFile;
    ZTAudioBuffer *_buffer;
    ZTAudioOutputQueue *_audioQueue;
    
    void *inputBuffer;
}
@property (retain, nonatomic) NSMutableData *data;
@property (nonatomic,assign)BOOL failed;
@property (nonatomic,assign)BOOL started;
@end

@implementation ZTAudioPlay

- (instancetype)initWithurl:(NSURL *)url{
    self = [super init];
    if (self) {
        [self dataSourceFromURL:url];
        [self initWithDataSource];
        
        inputBuffer = malloc(CHUNK_SIZE);
    }
    
    return self;
}

- (void)dataSourceFromURL:(NSURL *)url{
    
    id<ZTDataSource> dataSource = nil;
    if ([url.scheme isEqualToString:@"file"])
    {
        if ([url.pathExtension isEqualToString:@"flac"]) {
            dataSource = [[ZTFlacSource alloc]initWithUrl:url];
            if ([dataSource isKindOfClass:[ZTFlacSource class]]) {
                NSLog(@"flac");
            };
        }else{
            dataSource = [[ZTLocalSource alloc]initWithUrl:url];
        }
    }
    else if ([url.scheme caseInsensitiveCompare:@"http"] == NSOrderedSame || [url.scheme caseInsensitiveCompare:@"https"] == NSOrderedSame)
    {
         NSLog(@"http");
        dataSource = [[ZTHTTPSource alloc]initWithUrl:url];
    }
    
    self.dataSource = dataSource;
}


- (void)initWithDataSource{
    _offset = [self.dataSource offset];
    _fileSize = [self.dataSource fileSize];
//     _fileHandler = [NSFileHandle fileHandleForReadingAtPath:[self.dataSource filePath]];
//    _fileHandler = [self.dataSource fileHandler];
    if ([self.dataSource isOpenData] && _fileSize > 0)
    {
        _buffer = [ZTAudioBuffer buffer];
    }
    else
    {
//        [[self.dataSource fileHandler] closeFile];
        [self.dataSource closeFile];
        _failed = YES;
    }
}


#pragma mark - thread

- (BOOL)createAudioQueue
{
    if (_audioQueue)
    {
        return YES;
    }
    
    NSTimeInterval duration = self.duration;
    UInt64 audioDataByteCount = _usingAudioFile ? _audioFile.audioDataByteCount : _audioFileStream.audioDataByteCount;
    _bufferSize = 0;
    if (duration != 0)
    {
        _bufferSize = (0.2 / duration) * audioDataByteCount;
    }
    
    if (_bufferSize > 0)
    {
        AudioStreamBasicDescription format = _usingAudioFile ? _audioFile.format : _audioFileStream.format;
        NSData *magicCookie = _usingAudioFile ? [_audioFile fetchMagicCookie] : [_audioFileStream fetchMagicCookie];
        _audioQueue = [[ZTAudioOutputQueue alloc] initWithFormat:format bufferSize:_bufferSize macgicCookie:magicCookie];
        if (!_audioQueue.available)
        {
            _audioQueue = nil;
            return NO;
        }
    }
    return YES;
}
- (BOOL) isFlacSource{
    return  [self.dataSource isKindOfClass:[ZTFlacSource class]];
}

- (void)threadMain{
    _failed = YES;
    NSError *error = nil;
    //set audiosession category
    if ([[MCAudioSession sharedInstance] setCategory:kAudioSessionCategory_MediaPlayback error:NULL])
    {
        //active audiosession
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interruptHandler:) name:MCAudioSessionInterruptionNotification object:nil];
        if ([[MCAudioSession sharedInstance] setActive:YES error:NULL])
        {
            //create audioFileStream
            _audioFileStream = [[ZTAudioFileStream alloc] initWithFileType:[self.dataSource fileType] fileSize:[self.dataSource fileSize] error:&error];
            if (!error)
            {
                _failed = NO;
                _audioFileStream.delegate = self;
            }
        }
    }
    
    if (_failed)
    {
        [self cleanup];
        return;
    }
    
    [self setPlayState:ZTPlaybackStateBuffering];
    BOOL isEof = NO;
    while (self.status != ZTPlaybackStateStop && !_failed && _started)
    {
        
        @autoreleasepool
        {
            
             NSLog(@"reload");
            //read file & parse
            
            
            //TODO :AudioFile
            if (_usingAudioFile)
            {
                if (!_audioFile)
                {
                    _audioFile = [[ZTAudioFile alloc] initWithFilePath:nil fileType:[self.dataSource fileType]];
                }
                
                //TODO  audiofile
//                [_audioFile seekToTime:_seekTime];
//                if ([_buffer bufferedSize] < _bufferSize || !_audioQueue)
//                {
//                    NSArray *parsedData = [_audioFile parseData:&isEof];
//                    if (parsedData)
//                    {
//                        [_buffer enqueueFromDataArray:parsedData];
//                    }
//                    else
//                    {
//                        _failed = YES;
//                        break;
//                    }
//                }
            }
            else
            {
                if (_offset < _fileSize && (!_audioFileStream.readyToProducePackets || [_buffer bufferedSize] < _bufferSize || !_audioQueue))
                {

                     NSData *data = [self.dataSource  readDataOfLength:1000];

                    _offset += [data length];
                    if (_offset >= _fileSize)
                    {
                        isEof = YES;
                    }
                    [_audioFileStream parseData:data error:&error];
                    if (error)
                    {
                        _usingAudioFile = YES;
                        continue;
                    }
                }
            }
            
            
            
            if (_audioFileStream.readyToProducePackets || _usingAudioFile)
            {
                if (![self createAudioQueue])
                {
                    _failed = YES;
                    break;
                }
                
                if (!_audioQueue)
                {
                    continue;
                }
                
                if (self.status == ZTPlaybackStateFlushing && !_audioQueue.isRunning)
                {
                    break;
                }
                
                //stop
                if (_stopRequired)
                {
                    _stopRequired = NO;
                    _started = NO;
                    [_audioQueue stop:YES];
                    break;
                }
                
                //pause
                if (_pauseRequired)
                {
                    [self setStatusInternal:ZTPlaybackStatePause];
                    [_audioQueue pause];
                    [self _mutexWait];
                    _pauseRequired = NO;
                }
                
                //play
                if ([_buffer bufferedSize] >= _bufferSize || isEof)
                {
                    UInt32 packetCount;
                    AudioStreamPacketDescription *desces = NULL;
                    NSData *data = [_buffer dequeueDataWithSize:_bufferSize packetCount:&packetCount descriptions:&desces];
                    if (packetCount != 0)
                    {
                        [self setStatusInternal:ZTPlaybackStatePlaying];
                        _failed = ![_audioQueue playData:data packetCount:packetCount packetDescriptions:desces isEof:isEof];
                        free(desces);
                        if (_failed)
                        {
                            break;
                        }
                        
                        if (![_buffer hasData] && isEof && _audioQueue.isRunning)
                        {
                            [_audioQueue stop:NO];
                            [self setStatusInternal:ZTPlaybackStateFlushing];
                        }
                    }
                    else if (isEof)
                    {
                        //wait for end
                        if (![_buffer hasData] && _audioQueue.isRunning)
                        {
                            [_audioQueue stop:NO];
                            [self setStatusInternal:ZTPlaybackStateFlushing];
                        }
                    }
                    else
                    {
                        _failed = YES;
                        break;
                    }
                }
                
                //seek
                if (_seekRequired && self.duration != 0)
                {
                    [self setStatusInternal:ZTPlaybackStateBuffering];
                    
                    _timingOffset = _seekTime - _audioQueue.playedTime;
                    [_buffer clean];
                    if (_usingAudioFile)
                    {
                        [_audioFile seekToTime:_seekTime];
                    }
                    else
                    {
                        _offset = [_audioFileStream seekToTime:&_seekTime];
                        //
                        [self.dataSource  seekDataOffset:_offset];
                    }
                    _seekRequired = NO;
                    [_audioQueue reset];
                }
            }
        }
    }
//clean
[self cleanup];

}

- (void)cleanup
{
    //reset file
    _offset = 0;
    [self.dataSource seekDataOffset:0];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MCAudioSessionInterruptionNotification object:nil];
    
    //clean buffer
    [_buffer clean];
    
    _usingAudioFile = NO;
    //close audioFileStream
    [_audioFileStream close];
    _audioFileStream = nil;
    
    //close audiofile
    [_audioFile close];
    _audioFile = nil;
    
    //stop audioQueue
    [_audioQueue stop:YES];
    _audioQueue = nil;
    
    //destory mutex & cond
    [self _mutexDestory];
    
    _started = NO;
    _timingOffset = 0;
    _seekTime = 0;
    _seekRequired = NO;
    _pauseRequired = NO;
    _stopRequired = NO;
    
    //reset status
    [self setStatusInternal:ZTPlaybackStateStop];
}



#pragma mark - parser
- (void)audioFileStream:(ZTAudioFileStream *)audioFileStream audioDataParsed:(NSArray *)audioData
{
    [_buffer enqueueFromDataArray:audioData];
}

#pragma mark - progress
- (NSTimeInterval)progress
{
    if (_seekRequired)
    {
        return _seekTime;
    }
    return _timingOffset + _audioQueue.playedTime;
}

- (void)setProgress:(NSTimeInterval)progress
{
    _seekRequired = YES;
    _seekTime = progress;
}

- (NSTimeInterval)duration
{
    return _usingAudioFile ? _audioFile.duration : _audioFileStream.duration;
}

#pragma mark - PlayStatus
- (BOOL)isPlayingOrWaiting
{
    return self.status == ZTPlaybackStateBuffering || self.status == ZTPlaybackStatePlaying || self.status == ZTPlaybackStateFlushing;
}

- (ZTPlaybackState)status
{
    return _playState;
}

- (void)setStatusInternal:(ZTPlaybackState)status
{
    if (_playState == status)
    {
        return;
    }
    
    [self willChangeValueForKey:@"status"];
    _playState = status;
    [self didChangeValueForKey:@"status"];
}


#pragma mark - interrupt
- (void)interruptHandler:(NSNotification *)notification
{
    UInt32 interruptionState = [notification.userInfo[MCAudioSessionInterruptionStateKey] unsignedIntValue];
    
    if (interruptionState == kAudioSessionBeginInterruption)
    {
        _pausedByInterrupt = YES;
        [_audioQueue pause];
        [self setStatusInternal:ZTPlaybackStatePause];
        
    }
    else if (interruptionState == kAudioSessionEndInterruption)
    {
        AudioSessionInterruptionType interruptionType = [notification.userInfo[MCAudioSessionInterruptionTypeKey] unsignedIntValue];
        if (interruptionType == kAudioSessionInterruptionType_ShouldResume)
        {
            if (self.status == ZTPlaybackStatePause && _pausedByInterrupt)
            {
                if ([[MCAudioSession sharedInstance] setActive:YES error:NULL])
                {
                    [self play];
                }
            }
        }
    }
}


#pragma mark - mutex
- (void)_mutexInit
{
    pthread_mutex_init(&_mutex, NULL);
    pthread_cond_init(&_cond, NULL);
}

- (void)_mutexDestory
{
    pthread_mutex_destroy(&_mutex);
    pthread_cond_destroy(&_cond);
}

- (void)_mutexWait
{
    pthread_mutex_lock(&_mutex);
    pthread_cond_wait(&_cond, &_mutex);
    pthread_mutex_unlock(&_mutex);
}

- (void)_mutexSignal
{
    pthread_mutex_lock(&_mutex);
    pthread_cond_signal(&_cond);
    pthread_mutex_unlock(&_mutex);
}

#pragma mark - method

- (void)play{
    
    if (!_started)
    {
        _started = YES;
        [self _mutexInit];
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(threadMain) object:nil];
        [_thread start];
    }
    else
    {
        if (self.status == ZTPlaybackStatePause || _pauseRequired)
        {
            _pausedByInterrupt = NO;
            _pauseRequired = NO;
            if ([[MCAudioSession sharedInstance] setActive:YES error:NULL])
            {
                [[MCAudioSession sharedInstance] setCategory:kAudioSessionCategory_MediaPlayback error:NULL];
                [self _resume];
            }
        }

    }
}

- (void)_resume
{
    [_audioQueue resume];
    [self _mutexSignal];
}

- (void)pause
{
    if (self.isPlayingOrWaiting && self.status != ZTPlaybackStateFlushing)
    {
        _pauseRequired = YES;
    }
}

- (void)stop
{
    _stopRequired = YES;
    [self _mutexSignal];
}

@end
