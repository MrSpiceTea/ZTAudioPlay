//
//  ViewController.m
//  ZTAudioPlay
//
//  Created by 谢展图 on 15/7/25.
//  Copyright (c) 2015年 spice. All rights reserved.
//

#import "ViewController.h"
#import "ZTAudioPlay.h"
#import "NSTimer+BlocksSupport.h"

@interface ViewController (){
    ZTAudioPlay *_player;
       NSTimer *_timer;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString* path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp3"];
//      NSString* path = [[NSBundle mainBundle] pathForResource:@"flactest" ofType:@"flac"];
    NSURL* url = [NSURL fileURLWithPath:path];
    // Do any additional setup after loading the view, typically from a nib.
     _player = [[ZTAudioPlay alloc]initWithurl:url];
      [_player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [_player play];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - status kvo
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _player)
    {
        if ([keyPath isEqualToString:@"status"])
        {
            [self performSelectorOnMainThread:@selector(handleStatusChanged) withObject:nil waitUntilDone:NO];
        }
    }
}


- (void)handleStatusChanged
{
    if (_player.isPlayingOrWaiting)
    {
        [self.playOrPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
        [self startTimer];
        
    }
    else
    {
        [self.playOrPauseButton setTitle:@"Play" forState:UIControlStateNormal];
        [self stopTimer];
        [self progressMove];
    }
}

#pragma mark - timer
- (void)startTimer
{
    if (!_timer)
    {
        __weak typeof(self)weakSelf = self;
        _timer = [NSTimer bs_scheduledTimerWithTimeInterval:1 block:^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf progressMove];
        } repeats:YES];
        [_timer fire];
    }
}

- (void)stopTimer
{
    if (_timer)
    {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)progressMove
{
    if (!self.progressSlider.tracking)
    {
        if (_player.duration != 0)
        {
            self.progressSlider.value = _player.progress / _player.duration;
        }
        else
        {
            self.progressSlider.value = 0;
        }
    }
}



#pragma mark - action
- (IBAction)playOrPause:(id)sender
{
    if (_player.isPlayingOrWaiting)
    {
        [_player pause];
    }
    else
    {
        [_player play];
    }
}

- (IBAction)stop:(id)sender
{
    [_player stop];
}

- (IBAction)seek:(id)sender
{
    _player.progress = _player.duration * self.progressSlider.value;
}
@end
