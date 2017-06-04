//
//  SJDBMap.h
//  SJProject
//
//  Created by BlueDancer on 2017/6/3.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabase;

NS_ASSUME_NONNULL_BEGIN

/**
 *  父类字段未做处理.
 */
@interface SJDBMap : NSObject

/*!
 *  数据库对象
 */
@property (nonatomic, strong, readonly) FMDatabase *database;

/*!
 *  数据库路径
 */
@property (nonatomic, strong, readonly) NSString   *dbPath;

/*!
 *  使用此方法, 数据库将使用默认路径创建
 */
+ (instancetype)sharedServer;

/*!
 *  自定义数据库路径
 */
- (instancetype)initWithPath:(NSString *)path;

/*!
 *  根据类创建一个表
 */
- (void)createTabWithClass:(Class)cls callBlock:(void(^)(BOOL result))block;

/*!
 *  增数据或更新数据
 *  如果没有表, 会自动创建表
 */
- (void)insertOrUpdateDataWithModel:(id)model callBlock:(void(^)(BOOL result))block;

/*!
 *  删
 *  cls : 对应的类
 *  primaryValue : 主键或自增键值.
 */
- (void)deleteDataWithClass:(Class)cls primaryValue:(NSInteger)primaryValue callBlock:(void(^)(BOOL result))block;

/*!
 *  查
 *  返回和这个类有关的所有数据
 */
- (void)queryAllDataWithClass:(Class)cls completeCallBlock:(void(^)(NSArray<id> *data))block;

/*!
 *  查一条数据
 */
- (void)queryDataWithClass:(Class)cls primaryValue:(NSInteger)primaryValue completeCallBlock:(void (^)(id model))block;

@end


NS_ASSUME_NONNULL_END
