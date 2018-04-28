//
//  SJDatabaseMap.h
//  SJDBMapProject
//
//  Created by BlueDancer on 2018/4/25.
//  Copyright © 2018年 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJDBMapUseProtocol.h"
#import <sqlite3.h>

NS_ASSUME_NONNULL_BEGIN
@interface SJDatabaseMap : NSObject
@property (nonatomic, readonly) sqlite3 *database;
@property (nonatomic, strong, readonly) NSString *dbPath;
+ (instancetype)sharedServer;
- (instancetype)initWithPath:(NSString *)path NS_DESIGNATED_INITIALIZER;

- (void)performTasksWithSubThreadTask:(void (^)(SJDatabaseMap * _Nonnull mapper))subThreadTask
                        mainTreadTask:(void (^__nullable)(SJDatabaseMap * _Nonnull mapper))mainTreadTask;
@end


#pragma mark - Create

@interface SJDatabaseMap (Create)
/*!
 *  根据类创建一个表
 */
- (void)createOrUpdateTableWithClass:(Class<SJDBMapUseProtocol>)cls callBlock:(void(^ __nullable)(BOOL result))block;
@end


// MARK: InsertOrUpdate

@interface SJDatabaseMap (InsertOrUpdate)


// MARK: ---------------------------------------------------------
/*!
 *  数据库依据模型来存储. 所以在存储之前, 请将模型更新到最新状态, 再进行存储.
 */
// MARK: ---------------------------------------------------------


/*!
 *  插入数据或更新数据
 *  如果没有表, 会自动创建表
 *
 *  如果是模型具有自增主键, 将会随机插入.
 */
- (void)insertOrUpdateDataWithModel:(id<SJDBMapUseProtocol>)model callBlock:(void(^ __nullable)(BOOL result))block;

/*!
 *  批量插入或更新
 *  如果没有表, 会自动创建表
 *  数组中的模型, 可以不同
 *
 *  如果模型具有自增主键, 将会随机插入.
 */
- (void)insertOrUpdateDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models callBlock:(void (^ __nullable)(BOOL result))block;

/*!
 *  更新指定的属性字段
 *  提供需要更新的字段, 提高执行效率
 *
 *  property:@[@"name", @"age"] // 需要更新的属性
 */
- (void)update:(id<SJDBMapUseProtocol>)model properties:(NSArray<NSString *> *)properties callBlock:(void (^ __nullable)(BOOL result))block;
@end


// MARK: Delete

@interface SJDatabaseMap (Delete)

// MARK: ---------------------------------------------------------
/*!
 *  只会删除这个类(表)的数据, 相关联的类(表)的数据不会删除.
 */
// MARK: ---------------------------------------------------------


/*!
 *  删单条记录
 *  cls : 对应的类
 *  primaryValue : 主键或自增键值.
 */
- (void)deleteDataWithClass:(Class)cls primaryValue:(NSInteger)primaryValue callBlock:(void(^ __nullable)(BOOL result))block;

/*!
 *  批量删除
 *  primaryValues -> primaryValues
 */
- (void)deleteDataWithClass:(Class)cls primaryValues:(NSArray<NSNumber *> *)primaryValues callBlock:(void (^ __nullable)(BOOL result))block;

/*!
 *  批量删除
 */
- (void)deleteDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models callBlock:(void (^ __nullable)(BOOL result))block;

/*!
 *  删除表
 */
- (void)deleteDataWithClass:(Class)cls callBlock:(void (^ __nullable)(BOOL r))block;

@end



// MARK: Query


@interface SJDatabaseMap (Query)

/*!
 *  查所有记录
 *  返回和这个类有关的所有数据
 */
- (void)queryAllDataWithClass:(Class<SJDBMapUseProtocol>)cls completeCallBlock:(void(^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block;

/*!
 *  查单条记录
 */
- (void)queryDataWithClass:(Class)cls primaryValue:(NSInteger)primaryValue completeCallBlock:(void (^ __nullable)(id<SJDBMapUseProtocol> _Nullable model))block;

/*!
 *  查询
 *
 *  dict:
 *     @{
 *          @"name": @"A",
 *          @"tag": @"B"
 *      }
 *  or
 *     @{
 *          @"id" : @[@(0), @(2), @(3)],
 *          @"name":@[@"A", @"B", @"C"]
 *      } ==>>>> ... id in (0, 2, 3) and name in ('A', 'B', 'C')
 */
- (void)queryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict completeCallBlock:(void (^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block;

/*!
 *  查询指定区间数据
 */
- (void)queryDataWithClass:(Class)cls range:(NSRange)range completeCallBlock:(void(^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block;

/*!
 *  查记录的数量
 */
- (void)queryQuantityWithClass:(Class)cls completeCallBlock:(void (^ __nullable)(NSInteger quantity))block;


/*!
 *  模糊查询
 *
 *  default SJDatabaseMapFuzzyMatchBilateral
 *  dict: @{@"name":@"A", @"tag":@"B"}  Key -> Property, Value -> Part
 */
- (void)fuzzyQueryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict completeCallBlock:(void (^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block;

/*!
 *  模糊查询
 *  property : value
 */
- (void)fuzzyQueryDataWithClass:(Class)cls
                      queryDict:(NSDictionary *)dict
                          match:(SJDatabaseMapFuzzyMatch)match
              completeCallBlock:(void (^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block;

/*!
 *  模糊查询
 *
 *  例如: 匹配以 AB 开头, 以 EF 结尾.
 *       [DatabaseMapping fuzzyQueryDataWithClass:[Example Class]
 *                                       property:@"name"
 *                                          part1:@"AB"
 *                                          part2:@"EF"
 *                              completeCallBlock:nil]
 */
- (void)fuzzyQueryDataWithClass:(Class)cls
                       property:(NSString *)fields
                          part1:(NSString *)part1
                          part2:(NSString *)part2
              completeCallBlock:(void (^ __nullable)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block;

/*!
 *  根据多个主键查寻
 **/
- (void)queryDataWithClass:(Class)cls primaryValues:(NSArray<NSNumber *> *)primaryValues completeCallBlock:(void (^)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block;

/*!
 *  根据多个值查询
 **/
- (void)queryDataWithClass:(Class)cls property:(NSString *)property values:(NSArray *)values completeCallBlock:(void (^)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block;

@end


@interface SJDatabaseMap (SortQuery)

- (void)sortQueryWithClass:(Class)cls
                  property:(NSString *)property
                  sortType:(SJDatabaseMapSortType)sortType
         completeCallBlock:(void (^)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block;

- (void)sortQueryWithClass:(Class)cls
                  property:(NSString *)property
                  sortType:(SJDatabaseMapSortType)sortType
                     range:(NSRange)range
         completeCallBlock:(void (^)(NSArray<id<SJDBMapUseProtocol>> * _Nullable data))block;


- (void)sortQueryWithClass:(Class)cls
                 queryDict:(NSDictionary *)quertyDict
                 sortField:(NSString *)sortField
                  sortType:(SJDatabaseMapSortType)sortType
         completeCallBlock:(void (^)(NSArray<id<SJDBMapUseProtocol>> * _Nullable))block;


@end

NS_ASSUME_NONNULL_END
