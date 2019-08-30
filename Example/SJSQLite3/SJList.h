//
//  SJList.h
//  SJSQLite3_Example
//
//  Created by BlueDancer on 2019/8/30.
//  Copyright © 2019 changsanjiang@gmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJItem.h"

NS_ASSUME_NONNULL_BEGIN
@interface SJList : NSObject
@property (nonatomic) NSInteger id;
@property (nonatomic, copy, nullable) NSArray<SJItem *> *items;
@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic) short short_var;
@property (nonatomic) int int_var;
@property (nonatomic) long long_var;
@property (nonatomic) float float_var;
@property (nonatomic) double double_var;
@end
NS_ASSUME_NONNULL_END
