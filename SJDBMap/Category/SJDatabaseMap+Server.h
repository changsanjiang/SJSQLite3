//
//  SJDatabaseMap+Server.h
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/6/6.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SJDatabaseMap.h"

@class SJDBMapUnderstandingModel;

extern char *_sjmystrcat(char *dst, const char *src);

@interface SJDatabaseMap (Server)

/*!
 *  执行SQL语句
 */
- (void)sjExeSQL:(const char *)sql completeBlock:(void(^)(BOOL r))block;

/*!
 *  创建或更新一张表
 */
- (BOOL)sjCreateOrAlterTabWithClass:(Class)cls;

/*!
 *  自动创建相关的表
 */
- (void)sjAutoCreateOrAlterRelevanceTabWithClass:(Class)cls;

/*!
 *  查询表中的所有字段
 */
- (NSMutableArray<NSString *> *)sjQueryTabAllFieldsWithClass:(Class)cls;

/*!
 *  整理模型数据
 */
- (NSDictionary<NSString *, NSArray<id<SJDBMapUseProtocol>> *> *)sjPutInOrderModels:(NSArray<id> *)models;
- (NSDictionary<NSString *, NSArray<id<SJDBMapUseProtocol>> *> *)sjPutInOrderModelsSet:(NSSet<id> *)models;

/*!
 *  查询数据. 返回转换成型的模型数据
 */
- (NSArray<id<SJDBMapUseProtocol>> *)sjQueryConversionMolding:(Class)cls;

/*!
 *  根据主键值查询数据
 */
- (id<SJDBMapUseProtocol>)sjQueryConversionMolding:(Class)cls primaryValue:(NSInteger)primaryValue;

/*!
 *  查
 */
- (NSArray<NSDictionary *> *)sjQueryWithSQLStr:(NSString *)sqlStr;

/*!
 *  根据条件查询数据
 */
- (NSArray<id<SJDBMapUseProtocol>> *)sjQueryConversionMolding:(Class)cls dict:(NSDictionary *)dict;

/*!
 *  根据条件模糊查询
 */
- (NSArray<id<SJDBMapUseProtocol>> *)sjFuzzyQueryConversionMolding:(Class)cls match:(SJDatabaseMapFuzzyMatch)match dict:(NSDictionary *)dict;

/*!
 *  查询数据库原始存储数据
 */
- (NSArray<NSDictionary *> *)sjQueryRawStorageData:(Class)cls;

/*!
 *  查询数据库原始存储数据
 */
- (NSDictionary *)sjQueryRawStorageData:(Class)cls primaryValue:(NSInteger)primaryValue;

/*!
 *  插入
 */
- (BOOL)sjInsertOrUpdateDataWithModel:(id<SJDBMapUseProtocol>)obj uM:(SJDBMapUnderstandingModel *)uM;

- (BOOL)sjInsertOrUpdateDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models enableTransaction:(BOOL)enableTransaction;

/*!
 *  更新
 */
- (BOOL)sjUpdate:(id<SJDBMapUseProtocol>)model property:(NSArray<NSString *> *)fields;

- (BOOL)sjUpdate:(id<SJDBMapUseProtocol>)model insertedOrUpdatedValues:(NSDictionary<NSString *, id> *)insertedOrUpdatedValues;

/*!
 *  获取主键值
 */
- (NSArray<NSNumber *> *)sjGetPrimaryValues:(NSArray<id<SJDBMapUseProtocol>> *)models;
@end
