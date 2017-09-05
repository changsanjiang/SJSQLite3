//
//  SampleVideoTag.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/9/5.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SampleVideoTag.h"

@implementation SampleVideoTag

+(NSString *)primaryKey {
    return @"tagId";
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if ( !self ) return nil;
    [self setValuesForKeysWithDictionary:dict];
    return self;
}

@end
