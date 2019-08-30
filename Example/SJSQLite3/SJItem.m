//
//  SJItem.m
//  SJSQLite3_Example
//
//  Created by BlueDancer on 2019/8/30.
//  Copyright © 2019 changsanjiang@gmail.com. All rights reserved.
//

#import "SJItem.h"
#if __has_include(<YYModel/YYModel.h>)
#import <YYModel/NSObject+YYModel.h>
#elif __has_include(<YYKit/YYKit.h>)
#import <YYKit/YYKit.h>
#endif

@implementation SJItem
+ (nullable NSString *)sql_primaryKey {
    return @"item_id";
}

+ (nullable NSArray<NSString *> *)sql_autoincrementlist {
    return @[@"item_id"];
}

- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    if ( self ) {
        _name = name;
    }
    return self;
}

- (NSString *)description {
#if __has_include(<YYModel/YYModel.h>)
    return [self yy_modelDescription];
#elif __has_include(<YYKit/YYKit.h>)
    return [self modelDescription];
#endif
    return [super description];
}
@end
