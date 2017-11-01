//
//  PersonTag.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/6/4.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "PersonTag.h"
#import <YYKit.h>

@implementation PersonTag

+ (instancetype)tagWithID:(NSInteger)tagID des:(NSString *)des {
    PersonTag *tag = [PersonTag new];
    tag.tagID = tagID;
    tag.des = des;
    return tag;
}

// MARK: SJDBUseProtocol

+ (NSString *)primaryKey {
    return @"tagID";
}

@end
