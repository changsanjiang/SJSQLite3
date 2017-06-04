//
//  SJDBMap+GetInfo.h
//  SJProject
//
//  Created by BlueDancer on 2017/6/3.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SJDBMap.h"

@class SJDBMapUnderstandingModel, SJDBMapPrimaryKeyModel, SJDBMapAutoincrementPrimaryKeyModel, SJDBMapCorrespondingKeyModel, SJDBMapArrayCorrespondingKeysModel;

@interface SJDBMap (GetInfo)

/*!
 *  获取与该类相关的类
 */
- (NSMutableSet<Class> *)sjGetRelevanceClasses:(Class)cls;

/*!
 *  获取与该对象相关的对象
 */
- (NSMutableSet<id> *)sjGetRelevanceObjs:(id)rootObj;

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
- (NSString *)sjGetInsertOrUpdateSuffixSQL:(id)model;

/*!
 *  生成删除Sql语句
 */
- (NSString *)sjGetDeleteSQL:(Class)cls uM:(SJDBMapUnderstandingModel *)uM deletePrimary:(NSInteger)primaryValue;

/*!
 *  查询数据. 返回转换成型的模型数据
 */
- (NSArray<id> *)sjQueryConversionMolding:(Class)cls;

- (id)sjQueryConversionMolding:(Class)cls primaryValue:(NSInteger)primaryValue;

/*!
 *  查询数据库原始存储数据
 */
- (NSArray<NSDictionary *> *)sjQueryRawStorageData:(Class)cls;

/*!
 *  查询数据库原始存储数据
 */
- (NSDictionary *)sjQueryRawStorageData:(Class)cls primaryValue:(NSInteger)primaryValue;

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

@end
