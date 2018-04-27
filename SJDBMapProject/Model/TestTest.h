//
//  TestTest.h
//  SJDBMapProject
//
//  Created by BlueDancer on 2018/4/25.
//  Copyright © 2018年 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJDBMapUseProtocol.h"

@interface TestTest : NSObject<SJDBMapUseProtocol>

@property (nonatomic) NSInteger testId;

@property (nonatomic, strong) NSString *ttet;

- (void)print;
@end
