//
//  TestTest.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2018/4/25.
//  Copyright © 2018年 SanJiang. All rights reserved.
//

#import "TestTest.h"

@implementation TestTest {
    NSString *_test;
}

+ (NSString *)primaryKey {
    return @"testId";
}

- (void)print {
    NSLog(@"A: %@", _test);
}
@end
