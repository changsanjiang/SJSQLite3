//
//  NSObject+DBUG.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/10/28.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "NSObject+DBUG.h"
#import <NSObject+YYModel.h>

@implementation NSObject (DBUG)

- (NSString *)description {
    return [self modelDescription];
}

@end
