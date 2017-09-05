//
//  SampleVideoTag.h
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/9/5.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SJDBMapUseProtocol.h"

@interface SampleVideoTag : NSObject<SJDBMapUseProtocol>

@property (nonatomic, assign) NSInteger tagId;
@property (nonatomic, strong) NSString *title;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end
