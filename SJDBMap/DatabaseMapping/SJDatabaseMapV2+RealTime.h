//
//  SJDatabaseMapV2+RealTime.h
//  SJDBMapProject
//
//  Created by BlueDancer on 2018/4/25.
//  Copyright © 2018年 SanJiang. All rights reserved.
//

#import "SJDatabaseMapV2.h"

NS_ASSUME_NONNULL_BEGIN
@interface SJDatabaseMapV2 (RealTime)

#pragma mark create
/// 创建表(可能创建多个表)
- (BOOL)createOrUpdateTableWithClass:(Class<SJDBMapUseProtocol>)cls;

#pragma mark inser or update
/// 批量插入或更新
- (BOOL)insertOrUpdateDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models;
/// 提供需要更新的字段, 提高执行效率
- (BOOL)update:(id<SJDBMapUseProtocol>)model properties:(NSArray<NSString *> *)properties;

#pragma mark delete
/// 根据主键删除
- (BOOL)deleteDataWithClass:(Class)cls primaryValues:(NSArray<NSNumber *> *)primaryValues;
/// 提供模型删除
- (BOOL)deleteDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models;
/// 删除表
- (BOOL)deleteDataWithClass:(Class)cls;

#pragma mark query
- (nullable NSArray<id<SJDBMapUseProtocol>> *)queryAllDataWithClass:(Class<SJDBMapUseProtocol>)cls;

@end
NS_ASSUME_NONNULL_END
