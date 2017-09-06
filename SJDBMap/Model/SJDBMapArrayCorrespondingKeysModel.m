//
//  SJDBMapArrayCorrespondingKeysModel.m
//  SJProject
//
//  Created by BlueDancer on 2017/6/3.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SJDBMapArrayCorrespondingKeysModel.h"

#ifdef __SJDBug
#import <YYKit.h>
#endif

@implementation SJDBMapArrayCorrespondingKeysModel

+ (NSString *)autoincrementPrimaryKey {
    return @"aCKMID";
}

// MARK: YYKit
#ifdef __SJDBug
- (NSString *)description {
    return [self modelDescription];
}
#endif

@end
