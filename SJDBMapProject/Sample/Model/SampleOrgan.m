//
//  SampleOrgan.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/9/5.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SampleOrgan.h"

@implementation SampleOrgan

+ (NSString *)primaryKey {
    return @"code";
}

// MARK: Init

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if ( !self ) return nil;
    [self setValuesForKeysWithDictionary:dict];
    return self;
}

@end
