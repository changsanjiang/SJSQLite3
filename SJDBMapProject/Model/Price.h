//
//  Price.h
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/8/11.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SJDBMap.h"

@interface Price : NSObject<SJDBMapUseProtocol>

@property (nonatomic, assign) NSInteger priceId;
@property (nonatomic, assign) NSInteger price;

- (instancetype)initWithPriceId:(NSInteger)priceId price:(NSInteger)price;

@end
