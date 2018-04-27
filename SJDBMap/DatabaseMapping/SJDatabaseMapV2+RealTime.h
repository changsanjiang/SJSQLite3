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
- (BOOL)createOrUpdateTableWithClass:(Class<SJDBMapUseProtocol>)cls;

- (BOOL)insertOrUpdateDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models;
- (BOOL)update:(id<SJDBMapUseProtocol>)model property:(NSArray<NSString *> *)fields;
- (BOOL)update:(id<SJDBMapUseProtocol>)model insertedOrUpdatedValues:(NSDictionary<NSString *, id> *)insertedOrUpdatedValues;
- (BOOL)updateTheDeletedValuesInTheModel:(id<SJDBMapUseProtocol>)model;

@end
NS_ASSUME_NONNULL_END
