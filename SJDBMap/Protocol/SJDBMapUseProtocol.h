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
         *  对应键. A对象中包含B对象, 这个方法是设置在存储A对象时, 存储B对象的主键或者自增主键
         *
         *  Return Type :
         *              Key   : A中, B的属性名.
         *              Value : 依赖类B的主键或者自增主键
         *
         *  Example :
         *
         *    @ interface A : NSObject<SJDBMapUseProtocol>
         *    @ property (nonatomic, strong) B *b;
         *    @ property (nonatomic, strong) C *c;
         *    @ end
         *
         *    @ implementation A
         *    + (NSDictionary<NSString *, NSString *> *)correspondingKeys {
         *          return @{ @"b":@"b_id", @"c":@"c_id" };
         *    }
         *    @ end
         *
         *    @ interface B : NSObject<SJDBMapUseProtocol>
         *    @ property (nonatomic, assign) int b_id;
         *    @ end
         *
         *    @ implementation B
         *    + (NSString *)primaryKey { return @"b_id";}
         *    @ end
         *
         *    @ interface C : NSObject<SJDBMapUseProtocol>
         *    @ property (nonatomic, assign) int c_id;
         *    @ end
         *
         *    @ implementation C
         *    + (NSString *)primaryKey { return @"c_id";}
         *    @ end
         *  Warning : 依赖字段不能和类A中的属性重复.
         */
        + (NSDictionary<NSString *, NSString *> *)correspondingKeys;

        /*!
         *  数组中对应的模型类
         
         + (NSDictionary<NSString *,Class> *)arrayCorrespondingKeys {
            return @{@"videos":[SampleVideoModel class]};
         }
         */
        + (NSDictionary<NSString *, Class> *)arrayCorrespondingKeys;

@end
