//
//  SampleUser.h
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/9/5.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SJDBMapUseProtocol.h"

@interface SampleUser : NSObject<SJDBMapUseProtocol>

@property (nonatomic, assign) NSInteger userId;
@property (nonatomic, strong) NSString *nickname;
@property (nonatomic, strong) NSString *avatar;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end
