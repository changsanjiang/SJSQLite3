//
//  SJList.m
//  SJSQLite3_Example
//
//  Created by BlueDancer on 2019/8/30.
//  Copyright © 2019 changsanjiang@gmail.com. All rights reserved.
//

#import "SJList.h"
#if __has_include(<YYModel/YYModel.h>)
#import <YYModel/NSObject+YYModel.h>
#elif __has_include(<YYKit/YYKit.h>)
#import <YYKit/YYKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN
@implementation SJList
+ (nullable NSString *)sql_primaryKey {
    return @"id";
}

+ (nullable NSArray<NSString *> *)sql_autoincrementlist {
    return @[@"id"];
}

+ (nullable NSDictionary<NSString *, Class> *)sql_arrayPropertyGenericClass {
    return [self modelContainerPropertyGenericClass];
}

+ (nullable NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass {
    return @{@"items":SJItem.class};
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
NS_ASSUME_NONNULL_END
