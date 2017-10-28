//
//  SJDatabaseMap+GetInfo.h
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/6/6.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SJDatabaseMap.h"

@protocol SJDBMapUseProtocol;

@class SJDBMapUnderstandingModel, SJDBMapPrimaryKeyModel, SJDBMapAutoincrementPrimaryKeyModel, SJDBMapCorrespondingKeyModel, SJDBMapArrayCorrespondingKeysModel;

@interface SJDatabaseMap (GetInfo)

/*!
 *  获取与该类相关的类
 */
- (NSMutableSet<Class> *)sjGetRelevanceClasses:(Class)cls;

/*!
 *  获取与该对象相关的对象
 */
- (NSMutableSet<id<SJDBMapUseProtocol>> *)sjGetRelevanceObjs:(id<SJDBMapUseProtocol>)rootObj;

/*!
 *  获取与该类所有相关的协议
 */
- (NSArray<SJDBMapUnderstandingModel *> *)sjGetRelevanceUnderstandingModels:(Class)cls;

/*!
 *  获取某个类的协议实现
 */
- (SJDBMapUnderstandingModel *)sjGetUnderstandingWithClass:(Class)cls;

/*!
 *  生成插入或更新的前缀Sql语句
 *  example:
 *      INSERT OR REPLACE INTO 'SJPrice' ('price','priceID')
 */
- (NSString *)sjGetInsertOrUpdatePrefixSQL:(SJDBMapUnderstandingModel *)model;

/*!
 *  生成插入或更新的后缀Sql语句
 *  example:
 *      VALUES('15','1');
 */
- (NSString *)sjGetInsertOrUpdateSuffixSQL:(id<SJDBMapUseProtocol>)model;

/*!
 *  生成批量更新或插入数据
 */
- (NSString *)sjGetBatchInsertOrUpdateSubffixSQL:(NSArray<id<SJDBMapUseProtocol>> *)models;

/*!
 *  获取一般的更新语句
 */
- (NSString *)sjGetCommonUpdateSQLWithFields:(NSArray<NSString *> *)fields model:(id<SJDBMapUseProtocol>)model;

/*!
 *  生成删除Sql语句
 */
- (NSString *)sjGetDeleteSQL:(Class)cls uM:(SJDBMapUnderstandingModel *)uM deletePrimary:(NSInteger)primaryValue;

/*!
 *  生成批量删除Sql语句
 */
- (NSString *)sjGetBatchDeleteSQL:(Class)cls primaryValues:(NSArray<NSNumber *> *)primaryValues;

/*!
 *  获取该类主键
 */
- (SJDBMapPrimaryKeyModel *)sjGetPrimaryKey:(Class)cls;

/*!
 *  获取主键字段
 */
- (NSString *)sjGetPrimaryFields:(Class)cls;

/*!
 *  获取主键值
 */
- (NSNumber *)sjGetPrimaryValue:(id<SJDBMapUseProtocol>)model;

- (BOOL)sjHasPrimaryKey:(Class)cls;

/*!
 *  获取自增主键
 */
- (SJDBMapAutoincrementPrimaryKeyModel *)sjGetAutoincrementPrimaryKey:(Class)cls;

/*!
 *  获取自增主键字段
 */
- (NSString *)sjGetAutoPrimaryFields:(Class)cls;

/*!
 *  获取自增主键值
 */
- (NSNumber *)sjGetAutoPrimaryValue:(id<SJDBMapUseProtocol>)model;

/*!
 *  获取主键字段或自增主键字段
 */
- (NSString *)sjGetPrimaryOrAutoPrimaryFields:(Class)cls;

/*!
 *  获取主键值或者自增主键值
 */
- (NSNumber *)sjGetPrimaryOrAutoPrimaryValue:(id<SJDBMapUseProtocol>)model;

- (BOOL)sjHasAutoPrimaryKey:(Class)cls;

/*!
 *  获取数组相应键
 */
- (NSArray<SJDBMapArrayCorrespondingKeysModel *> *)sjGetArrayCorrespondingKeys:(Class)cls;

/*!
 *  dict keys
 */
- (NSArray<NSString *> *)sjGetArrCorrespondingOriginFields:(Class)cls;

/*!
 *  dict values
 */
- (NSArray<Class> *)sjGetArrCorrespondingFields:(Class)cls;

/*!
 *  获取相应键
 */
- (NSArray<SJDBMapCorrespondingKeyModel *>*)sjGetCorrespondingKeys:(Class)cls;

/*!
 *  dict keys
 */
- (NSArray<NSString *> *)sjGetCorrespondingOriginFields:(Class)cls;

/*!
 *  dict values
 */
- (NSArray<NSString *> *)sjGetCorrespondingFields:(Class)cls;

/*!
 *  获取表名称
 */
- (const char *)sjGetTabName:(Class)cls;

/*!
 *  根据ID排序, 获取最后一条数据的ID
 */
- (NSNumber *)sjGetLastDataIDWithClass:(Class)cls autoincrementPrimaryKeyModel:(SJDBMapAutoincrementPrimaryKeyModel *)aPKM;

/*!
 *  {"PersonTag":[0,1,2]}
 *  {"Goods":[13,14]}
 */
- (NSString *)sjGetArrModelPrimaryValues:(NSArray<id<SJDBMapUseProtocol>> *)models;

@end
