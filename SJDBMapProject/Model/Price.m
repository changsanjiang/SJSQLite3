//
//  Price.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/8/11.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "Price.h"
#import <YYKit.h>

@implementation Price

+ (NSString *)primaryKey {
    return @"priceId";
}

- (instancetype)initWithPriceId:(NSInteger)priceId price:(NSInteger)price {
    self = [super init];
    if ( !self ) return nil;
    _priceId = priceId;
    _price = price;
    return self;
}

@end
