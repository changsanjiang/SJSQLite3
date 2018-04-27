//
//  SJDatabaseMapV2+RealTime.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2018/4/25.
//  Copyright © 2018年 SanJiang. All rights reserved.
//

#import "SJDatabaseMapV2+RealTime.h"
#import "SJDatabaseFunctions.h"

@implementation SJDatabaseMapV2 (RealTime)
- (BOOL)createOrUpdateTableWithClass:(Class<SJDBMapUseProtocol>)cls {
    NSMutableArray<SJDatabaseMapTableCarrier *> *associatedCarrierM = [NSMutableArray array];
    SJDatabaseMapTableCarrier *carrier = [[SJDatabaseMapTableCarrier alloc] initWithClass:cls];
    [carrier parseCorrespondingKeysAddToContainer:associatedCarrierM];
    NSMutableArray<SJDatabaseMapTableCarrier *> *existsM = [NSMutableArray array];
    NSMutableArray<SJDatabaseMapTableCarrier *> *nonexistentM = [NSMutableArray array];
    [associatedCarrierM enumerateObjectsUsingBlock:^(SJDatabaseMapTableCarrier * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ( sj_table_exists(self.database, sj_table_name(obj.cls)) ) {
            [existsM addObject:obj];
        }
        else {
            [nonexistentM addObject:obj];
        }
    }];
    
    __block BOOL result = YES;
    [nonexistentM enumerateObjectsUsingBlock:^(SJDatabaseMapTableCarrier * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        result = sj_table_create(self.database, obj);
        if ( !result ) *stop = YES;
    }];
    
    [existsM enumerateObjectsUsingBlock:^(SJDatabaseMapTableCarrier * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        result = sj_table_update(self.database, obj);
        if ( !result ) *stop = YES;
    }];
    
    return result;
}

- (BOOL)_autoCreateOrUpdateClassesWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models {
    __block BOOL result = NO;
    NSMutableSet<Class<SJDBMapUseProtocol>> *classesM = [NSMutableSet new];
    [models enumerateObjectsUsingBlock:^(id<SJDBMapUseProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [classesM addObject:[obj class]];
    }];
    
    [classesM enumerateObjectsUsingBlock:^(Class<SJDBMapUseProtocol>  _Nonnull cls, BOOL * _Nonnull stop) {
        result = [self createOrUpdateTableWithClass:cls];
        if ( !result ) *stop = YES;
    }];
    return result;
}

#pragma mark -
- (BOOL)insertOrUpdateDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models {
    if ( !models ) return NO;
    BOOL result = [self _autoCreateOrUpdateClassesWithModels:models];
    if ( !result ) return NO;
    
    NSMutableDictionary<Class, NSArray<SJDatabaseMapTableCarrier *> *> *classes = nil;
    [models enumerateObjectsUsingBlock:^(id<SJDBMapUseProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<SJDatabaseMapTableCarrier *> *contaienr = classes[[obj class]];
        if ( !contaienr ) {
            contaienr = [NSMutableArray array];
            [[[SJDatabaseMapTableCarrier alloc] initWithClass:[obj class]] parseCorrespondingKeysAddToContainer:(NSMutableArray *)contaienr];
        }
    }];
    
    sj_transaction(self.database, ^{
        SJDatabaseMapCache *cache = [SJDatabaseMapCache new];
        [models enumerateObjectsUsingBlock:^(id<SJDBMapUseProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            sj_value_insert_or_update(self.database, obj, classes[[obj class]], cache);
        }];
    });
    return result;
}

//- (BOOL)update:(id<SJDBMapUseProtocol>)model property:(NSArray<NSString *> *)fields {
//
//}
//
//- (BOOL)update:(id<SJDBMapUseProtocol>)model insertedOrUpdatedValues:(NSDictionary<NSString *, id> *)insertedOrUpdatedValues {
//
//}
//
//- (BOOL)updateTheDeletedValuesInTheModel:(id<SJDBMapUseProtocol>)model {
//
//}

@end
