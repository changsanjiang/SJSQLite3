//
//  SampleOrgan.h
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/9/5.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SJDBMapUseProtocol.h"

@interface SampleOrgan : NSObject<SJDBMapUseProtocol>

@property (nonatomic, assign) NSInteger code;
@property (nonatomic, strong) NSString *identification;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end
