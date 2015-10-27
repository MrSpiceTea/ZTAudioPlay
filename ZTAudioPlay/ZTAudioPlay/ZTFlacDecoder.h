//
//  ZTFlacDecoder.h
//  ZTAudioPlay
//
//  Created by 谢展图 on 15/7/26.
//  Copyright (c) 2015年 spice. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZTFlacSource.h"

@interface ZTFlacDecoder : NSObject

- (BOOL)open:(ZTFlacSource *)source;

- (NSDictionary *)properties ;

- (int)readAudio:(void *)buffer frames:(UInt32)frames ;

@end
