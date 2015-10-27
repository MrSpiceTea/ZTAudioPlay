//
//  ZTAudioParsedData.h
//  ZTAudioPlay
//
//  Created by 谢展图 on 15/7/25.
//  Copyright (c) 2015年 spice. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudioTypes.h>

@interface ZTAudioParsedData : NSObject

@property (nonatomic,readonly) NSData *data;
@property (nonatomic,readonly) AudioStreamPacketDescription packetDescription;


+ (instancetype)parsedAudioDataWithBytes:(const void *)bytes
                       packetDescription:(AudioStreamPacketDescription)packetDescription;



@end
