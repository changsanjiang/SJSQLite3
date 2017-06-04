//
//  PersonTag.h
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/6/4.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJDBMapUseProtocol.h"

@interface PersonTag : NSObject<SJDBMapUseProtocol>

@property (nonatomic, assign) NSInteger tagID;
@property (nonatomic, strong) NSString *des;

+ (instancetype)tagWithID:(NSInteger)tagID des:(NSString *)des;

@end
