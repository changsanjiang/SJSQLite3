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
    __block BOOL result = [self _autoCreateOrUpdateClassesWithModels:models];
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
            result = sj_value_insert_or_update(self.database, obj, classes[[obj class]], cache);
            if ( !result ) {
                *stop = YES;
            }
        }];
    });
    return result;
}

- (BOOL)update:(id<SJDBMapUseProtocol>)model properties:(NSArray<NSString *> *)properties {
    if ( !model ) return NO;
    NSMutableArray<SJDatabaseMapTableCarrier *> *container = [NSMutableArray array];
    SJDatabaseMapTableCarrier *carrier = [[SJDatabaseMapTableCarrier alloc] initWithClass:[model class]];
    [carrier parseCorrespondingKeysAddToContainer:container];
    __block BOOL result = NO;
    sj_transaction(self.database, ^{
        result = sj_value_update(self.database, model, properties, container, [SJDatabaseMapCache new]);
    });
    return result;
}

#pragma mark -

- (BOOL)deleteDataWithClass:(Class)cls primaryValues:(NSArray<NSNumber *> *)primaryValues {
    if ( !cls ) return NO;
    if ( primaryValues.count == 0 ) return NO;
    SJDatabaseMapTableCarrier *carrier = [[SJDatabaseMapTableCarrier alloc] initWithClass:cls];
    const char *table_name = sj_table_name(cls);
    return sj_value_delete(self.database, table_name, carrier.primaryKeyOrAutoincrementPrimaryKey.UTF8String, primaryValues);
}

- (BOOL)deleteDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models {
    if ( models.count == 0 ) return NO;
    NSMutableDictionary<NSString *, NSMutableArray *> *dictM = [NSMutableDictionary new];
    [models enumerateObjectsUsingBlock:^(id<SJDBMapUseProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *key = NSStringFromClass([obj class]);
        if ( !dictM[key] ) [dictM setObject:[NSMutableArray array] forKey:key];
        [dictM[key] addObject:obj];
    }];
    
    __block BOOL result = NO;
    [dictM enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray * _Nonnull obj, BOOL * _Nonnull stop) {
        SJDatabaseMapTableCarrier *carrier = [[SJDatabaseMapTableCarrier alloc] initWithClass:NSClassFromString(key)];
        NSMutableArray *values = [NSMutableArray array];
        [models enumerateObjectsUsingBlock:^(id<SJDBMapUseProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [values addObject:[(id)obj valueForKey:carrier.primaryKeyOrAutoincrementPrimaryKey]];
        }];
        result = [self deleteDataWithClass:NSClassFromString(key) primaryValues:values];
        if ( !result ) *stop = YES;
    }];
    return result;
}

- (BOOL)deleteDataWithClass:(Class)cls {
    if ( !cls ) return NO;
    return sj_table_delete(self.database, sj_table_name(cls));
}

@end
