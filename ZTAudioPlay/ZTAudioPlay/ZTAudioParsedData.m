//
//  ZTAudioParsedData.m
//  ZTAudioPlay
//
//  Created by 谢展图 on 15/7/25.
//  Copyright (c) 2015年 spice. All rights reserved.
//

#import "ZTAudioParsedData.h"


@implementation ZTAudioParsedData

+ (instancetype)parsedAudioDataWithBytes:(const void *)bytes
                       packetDescription:(AudioStreamPacketDescription)packetDescription
{
    return [[self alloc] initWithBytes:bytes
                     packetDescription:packetDescription];
}

- (instancetype)initWithBytes:(const void *)bytes packetDescription:(AudioStreamPacketDescription)packetDescription
{
    if (bytes == NULL || packetDescription.mDataByteSize == 0)
    {
        return nil;
    }
    
    self = [super init];
    if (self)
    {
        _data = [NSData dataWithBytes:bytes length:packetDescription.mDataByteSize];
        _packetDescription = packetDescription;
    }
    return self;
}

@end
