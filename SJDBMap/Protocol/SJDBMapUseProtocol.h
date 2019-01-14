//
//  SJDBMapUseProtocol.h
//  SJProject
//
//  Created by BlueDancer on 2017/6/3.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SJDatabaseMapFuzzyMatch) {
    /*!
     *  匹配左右两侧
     *  ...A...
     */
    SJDatabaseMapFuzzyMatchBilateral = 0,
    /*!
     *  匹配以什么开头
     *  ABC.....
     */
    SJDatabaseMapFuzzyMatchFront,
    /*!
     *  匹配以什么结尾
     *  ...DEF
     */
    SJDatabaseMapFuzzyMatchLater,
};


typedef NS_ENUM(NSUInteger, SJDatabaseMapSortType) {
    SJDatabaseMapSortType_Asc,  // 升序, 由小到大
    SJDatabaseMapSortType_Desc, // 降序
};

@protocol SJDBMapUseProtocol <NSObject>

@optional
        /*!
         *  主键
         *  NSInteger.
         *
         *  + (NSString *)primaryKey { return @"personID";}
         */
        + (NSString *)primaryKey;

        /*!
         *  自增主键
         *  NSInteger.
         *
         *  + (NSString *)autoincrementPrimaryKey { return @"personID";}
         */
        + (NSString *)autoincrementPrimaryKey;

        /*!
         *  数组中对应的模型类
         
         + (NSDictionary<NSString *,Class> *)arrayCorrespondingKeys {
            return @{@"videos":[SampleVideoModel class]};
         }
         */
        + (NSDictionary<NSString *, Class> *)arrayCorrespondingKeys;

        + (NSArray<NSString *> *)tab_ignoredIvarList;
@end
