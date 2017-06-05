//
//  Person.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/6/4.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "Person.h"
#import "PersonTag.h"
#import "Book.h"

@implementation Person

+ (NSString *)primaryKey {
    return @"personID";
}

+ (NSDictionary<NSString *,Class> *)arrayCorrespondingKeys {
    return @{@"tags":[PersonTag class]};
}

+ (NSDictionary<NSString *,NSString *> *)correspondingKeys {
    return @{@"aBook":@"bookID"};
}

@end
