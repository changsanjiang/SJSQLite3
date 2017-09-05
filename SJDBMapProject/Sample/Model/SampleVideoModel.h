//
//  SampleVideoModel.h
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/9/5.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SJDBMapUseProtocol.h"

@class SampleVideoTag, SampleUser, SampleOrgan;

@interface SampleVideoModel : NSObject<SJDBMapUseProtocol>

@property (nonatomic, assign) NSInteger videoId;
@property (nonatomic, assign) NSUInteger createTime;
@property (nonatomic, assign) NSUInteger playTimes;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *videoCoverUrl;
@property (nonatomic, strong) NSString *videoUrl;
@property (nonatomic, strong) NSArray<SampleVideoTag *> *tags;
@property (nonatomic, strong) NSArray<SampleUser *> *likedUsers;
@property (nonatomic, strong) SampleOrgan *organ;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end
