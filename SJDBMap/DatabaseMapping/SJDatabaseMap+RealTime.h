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

- (id<SJDBMapUseProtocol>)sjQueryDataWithClass:(Class)cls primaryValue:(NSInteger)primaryValue;

- (NSArray<id<SJDBMapUseProtocol>> * __nullable)queryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict;

- (NSArray<id<SJDBMapUseProtocol>> * __nullable)queryDataWithClass:(Class)cls range:(NSRange)range;

- (NSArray<id<SJDBMapUseProtocol>> * _Nullable)fuzzyQueryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict match:(SJDatabaseMapFuzzyMatch)match;

@end


NS_ASSUME_NONNULL_END
