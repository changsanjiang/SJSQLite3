//
//  SJItem.h
//  SJSQLite3_Example
//
//  Created by BlueDancer on 2019/8/30.
//  Copyright © 2019 changsanjiang@gmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SJItem : NSObject
- (instancetype)initWithName:(NSString *)name;
@property (nonatomic) NSInteger item_id;
@property (nonatomic, copy, nullable) NSString *name;
@end

NS_ASSUME_NONNULL_END
