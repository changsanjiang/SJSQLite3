//
//  SJDatabaseMap+RealTime.h
//  SJDBMapProject
//
//  Created by BlueDancer on 2018/4/25.
//  Copyright © 2018年 SanJiang. All rights reserved.
//

#import "SJDatabaseMap.h"

#pragma mark - =================================
#pragma mark - real-time CRUD
#pragma mark - 请在必要的情况下使用, 尽量少用
#pragma mark - =================================


NS_ASSUME_NONNULL_BEGIN
@interface SJDatabaseMap (RealTime)

#pragma mark create
/// 创建表(可能创建多个表)
- (BOOL)createOrUpdateTableWithClass:(Class<SJDBMapUseProtocol>)cls;

#pragma mark inser or update
/// 批量插入或更新
- (BOOL)insertOrUpdateDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models;
/// 提供需要更新的字段, 提高执行效率
- (BOOL)update:(id<SJDBMapUseProtocol>)model properties:(NSArray<NSString *> *)properties;
- (BOOL)updates:(NSArray<id<SJDBMapUseProtocol>> *)models properties:(NSArray<NSString *> *)properties;

#pragma mark delete
/// 根据主键删除
- (BOOL)deleteDataWithClass:(Class)cls primaryValues:(NSArray<NSNumber *> *)primaryValues;
/// 提供模型删除
- (BOOL)deleteDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models;
/// 删除表
- (BOOL)deleteDataWithClass:(Class)cls;

#pragma mark query
- (nullable NSArray<id<SJDBMapUseProtocol>> *)queryWithSqlStr:(NSString *)sql class:(Class<SJDBMapUseProtocol>)cls;
- (nullable NSArray<id<SJDBMapUseProtocol>> *)queryAllDataWithClass:(Class<SJDBMapUseProtocol>)cls;
- (nullable id<SJDBMapUseProtocol>)queryDataWithClass:(Class)cls primaryValue:(NSInteger)primaryValue;
- (NSArray<id<SJDBMapUseProtocol>> * __nullable)queryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict;
- (NSArray<id<SJDBMapUseProtocol>> * __nullable)queryDataWithClass:(Class)cls range:(NSRange)range;
- (NSInteger)queryQuantityWithClass:(Class)cls;

- (NSArray<id<SJDBMapUseProtocol>> * _Nullable)fuzzyQueryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict match:(SJDatabaseMapFuzzyMatch)match;
- (NSArray<id<SJDBMapUseProtocol>> * _Nullable)fuzzyQueryDataWithClass:(Class)cls property:(NSString *)fields part1:(NSString *)part1 part2:(NSString *)part2;
- (NSArray<id<SJDBMapUseProtocol>> * _Nullable)queryDataWithClass:(Class)cls primaryValues:(NSArray<NSNumber *> *)primaryValues;
- (NSArray<id<SJDBMapUseProtocol>> * _Nullable)queryDataWithClass:(Class)cls property:(NSString *)property values:(NSArray *)values;

#pragma mark sort query
- (NSArray<id<SJDBMapUseProtocol>> * _Nullable)sortQueryWithClass:(Class)cls property:(NSString *)property sortType:(SJDatabaseMapSortType)sortType;
- (NSArray<id<SJDBMapUseProtocol>> * _Nullable)sortQueryWithClass:(Class)cls property:(NSString *)property sortType:(SJDatabaseMapSortType)sortType range:(NSRange)range;
- (NSArray<id<SJDBMapUseProtocol>> * _Nullable)sortQueryWithClass:(Class)cls queryDict:(NSDictionary *)quertyDict sortField:(NSString *)sortField sortType:(SJDatabaseMapSortType)sortType;

@end
NS_ASSUME_NONNULL_END
