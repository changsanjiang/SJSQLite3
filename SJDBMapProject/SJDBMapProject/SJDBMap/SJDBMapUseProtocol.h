//
//  SJDBMapUseProtocol.h
//  SJProject
//
//  Created by BlueDancer on 2017/6/3.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SJDBMapUseProtocol <NSObject>

@optional
        /*!
         *  主键
         *  NSInteger.
         */
        + (NSString *)primaryKey;

        /*!
         *  自增主键
         *  NSInteger.
         */
        + (NSString *)autoincrementPrimaryKey;

        /*!
         *  对应键. A对象中包含B对象, 这个方法是设置在存储A对象时, 存储B对象的主键或者自增主键
         *
         *  Return Type :
         *              key : A中, B的属性名.
         *              value : 依赖类B的主键或者自增主键
         *
         *  Example :
         *
         *      *********
         *    @ interface A : NSObject
         *    @ property (nonatomic, strong) B *c;
         *    @ end
         *    @ implementation A
         *    + (NSDictionary<NSString *, NSString *> *)correspondingKeys { return @{@"c":@"id"}};
         *    @ end
         *
         *      *********
         *    @ interface B : NSObject
         *    @ property (nonatomic, assign) int id;
         *    @ end
         *
         *  Warning : 依赖字段不能和类A中的属性重复.
         */
        + (NSDictionary<NSString *, NSString *> *)correspondingKeys;

        /*!
         *  数组中对应的模型类
         */
        + (NSDictionary<NSString *, Class> *)arrayCorrespondingKeys;

@end
