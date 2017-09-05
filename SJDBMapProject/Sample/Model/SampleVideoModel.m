//
//  SampleVideoModel.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/9/5.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SampleVideoModel.h"

#import "SampleVideoTag.h"

#import "SampleUser.h"

#import "SampleOrgan.h"

@implementation SampleVideoModel

+(NSString *)primaryKey {
    return @"videoId";
}

// model property
+ (NSDictionary<NSString *,NSString *> *)correspondingKeys {
    return @{
             @"organ":@"code",
             };
}

// arr model property
+ (NSDictionary<NSString *,Class> *)arrayCorrespondingKeys {
    return @{
             @"tags":[SampleVideoTag class],
             @"likedUsers":[SampleUser class],
             };
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if ( !self ) return nil;
    [self setValuesForKeysWithDictionary:dict];
    
    NSMutableArray *tmpArrM = [NSMutableArray new];
    
    // tags
    [dict[@"tags"] enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self _arrM:tmpArrM safeAddObject:[[SampleVideoTag alloc] initWithDictionary:obj]];
    }];
    self.tags = tmpArrM.copy;
    
    [tmpArrM removeAllObjects];
    
    // likedUsers
    [dict[@"likedUsers"] enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self _arrM:tmpArrM safeAddObject:[[SampleUser alloc] initWithDictionary:obj]];
    }];
    self.likedUsers = tmpArrM.copy;
    
    [tmpArrM removeAllObjects];
    
    // organ
    self.organ = [[SampleOrgan alloc] initWithDictionary:dict[@"organ"]];
    
    return self;
}

- (void)_arrM:(NSMutableArray *)arrM safeAddObject:(id)obj {
    if ( !obj ) return;
    [arrM addObject:obj];
}

@end
