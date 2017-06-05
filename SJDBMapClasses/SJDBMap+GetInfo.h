//
//  SJDBMap+GetInfo.h
//  SJProject
//
//  Created by BlueDancer on 2017/6/3.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SJDBMap.h"

@protocol SJDBMapUseProtocol;

@class SJDBMapUnderstandingModel, SJDBMapPrimaryKeyModel, SJDBMapAutoincrementPrimaryKeyModel, SJDBMapCorrespondingKeyModel, SJDBMapArrayCorrespondingKeysModel;

@interface SJDBMap (GetInfo)

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
- (NSString *)sjBatchGetInsertOrUpdateSubffixSQL:(NSArray<id<SJDBMapUseProtocol>> *)models;

/*!
 *  生成删除Sql语句
 */
- (NSString *)sjGetDeleteSQL:(Class)cls uM:(SJDBMapUnderstandingModel *)uM deletePrimary:(NSInteger)primaryValue;

/*!
 *  获取该类主键
 */
- (SJDBMapPrimaryKeyModel *)sjGetPrimaryKey:(Class)cls;

/*!
 *  获取自增主键
 */
- (SJDBMapAutoincrementPrimaryKeyModel *)sjGetAutoincrementPrimaryKey:(Class)cls;

/*!
 *  获取数组相应键
 */
- (NSArray<SJDBMapArrayCorrespondingKeysModel *> *)sjGetArrayCorrespondingKeys:(Class)cls;

/*!
 *  获取相应键
 */
- (NSArray<SJDBMapCorrespondingKeyModel *>*)sjGetCorrespondingKeys:(Class)cls;

/*!
 *  获取表名称
 */
- (const char *)sjGetTabName:(Class)cls;

@end
