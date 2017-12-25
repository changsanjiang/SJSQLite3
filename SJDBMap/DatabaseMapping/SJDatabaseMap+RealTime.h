//
//  SJDatabaseMap+RealTime.h
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/11/1.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SJDatabaseMap.h"


@class SJDBMapUnderstandingModel, SJDBMapQueryCache;

NS_ASSUME_NONNULL_BEGIN

extern char *_sjmystrcat(char *dst, const char *src);

@interface SJDatabaseMap (RealTime)

- (id)filterValue:(id)target;

/*!
 *  查询表中的所有字段 */
- (NSMutableArray<NSString *> * __nullable)sjQueryTabAllFieldsWithClass:(Class)cls;




#pragma mark - =================================
#pragma mark - real-time CRUD
#pragma mark - 请在必要的情况下使用, 尽量少用
#pragma mark - =================================

#pragma mark -

- (BOOL)createTabWithClass:(Class)cls;

#pragma mark - insert or update
- (BOOL)insertOrUpdateDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models;

- (BOOL)update:(id<SJDBMapUseProtocol>)model property:(NSArray<NSString *> *)fields;

- (BOOL)update:(id<SJDBMapUseProtocol>)model insertedOrUpdatedValues:(NSDictionary<NSString *, id> *)insertedOrUpdatedValues;

- (BOOL)updateTheDeletedValuesInTheModel:(id<SJDBMapUseProtocol>)model;

#pragma mark - delete
- (BOOL)deleteDataWithClass:(Class)cls primaryValue:(NSInteger)primaryValue;

- (BOOL)deleteDataWithClass:(Class)cls primaryValues:(NSArray<NSNumber *> *)primaryValues;

- (BOOL)deleteDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models;

- (BOOL)deleteDataWithClass:(Class)cls;

#pragma mark - query
- (NSArray<id<SJDBMapUseProtocol>> * __nullable)queryAllDataWithClass:(Class)cls;

- (id<SJDBMapUseProtocol>)queryDataWithClass:(Class)cls primaryValue:(NSInteger)primaryValue;

- (NSArray<id<SJDBMapUseProtocol>> * __nullable)queryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict;

- (NSInteger)queryQuantityWithClass:(Class)cls property:(NSString * __nullable)property;

- (NSArray<id<SJDBMapUseProtocol>> * __nullable)queryDataWithClass:(Class)cls range:(NSRange)range;

- (NSArray<id<SJDBMapUseProtocol>> * _Nullable)fuzzyQueryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict match:(SJDatabaseMapFuzzyMatch)match;

- (NSArray<id<SJDBMapUseProtocol>> * _Nullable)fuzzyQueryDataWithClass:(Class)cls property:(NSString *)fields part1:(NSString *)part1 part2:(NSString *)part2;

- (NSArray<id<SJDBMapUseProtocol>> * _Nullable)queryDataWithClass:(Class)cls primaryValues:(NSArray<NSNumber *> *)primaryValues;

- (NSArray<id<SJDBMapUseProtocol>> * _Nullable)queryDataWithClass:(Class)cls property:(NSString *)property values:(NSArray *)values;
- (NSArray<id<SJDBMapUseProtocol>> * _Nullable)sortQueryWithClass:(Class)cls property:(NSString *)property sortType:(SJDatabaseMapSortType)sortType;
@end


NS_ASSUME_NONNULL_END

