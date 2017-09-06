//
//  SJDBMapAutoincrementPrimaryKeyModel.m
//  SJProject
//
//  Created by BlueDancer on 2017/6/3.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SJDBMapAutoincrementPrimaryKeyModel.h"

#ifdef __SJDBug
#import <YYKit.h>
#endif

@implementation SJDBMapAutoincrementPrimaryKeyModel

+ (NSString *)autoincrementPrimaryKey {
    return @"aPKMID";
}

#ifdef __SJDBug
- (NSString *)description {
    return [self modelDescription];
}
#endif
@end
