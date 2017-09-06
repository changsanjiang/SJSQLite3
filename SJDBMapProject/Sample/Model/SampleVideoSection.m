//
//  SampleVideoSection.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/9/5.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SampleVideoSection.h"

#import "SampleVideoModel.h"

#import <NSObject+YYModel.h>

@implementation SampleVideoSection

+ (NSString *)primaryKey {
    return @"sectionId";
}

+ (NSDictionary<NSString *,Class> *)arrayCorrespondingKeys {
    return @{@"videos":[SampleVideoModel class]};
}

- (NSString *)description {
    return [self modelDescription];
}

@end
