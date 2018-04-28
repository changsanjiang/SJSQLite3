//
//  SJDatabaseMap+RealTime.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2018/4/25.
//  Copyright © 2018年 SanJiang. All rights reserved.
//

#import "SJDatabaseMap+RealTime.h"
#import "SJDatabaseFunctions.h"

@implementation SJDatabaseMap (RealTime)
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

#pragma mark -
- (nullable NSArray<id<SJDBMapUseProtocol>> *)queryAllDataWithClass:(Class<SJDBMapUseProtocol>)cls {
    if ( !cls ) return nil;
    NSString *sql_str = [NSString stringWithFormat:@"SELECT *FROM %s;", sj_table_name(cls)];
    return sj_value_query(self.database, sql_str.UTF8String, cls, nil, nil);
}

- (nullable id<SJDBMapUseProtocol>)queryDataWithClass:(Class)cls primaryValue:(NSInteger)primaryValue {
    if ( !cls ) return nil;
    SJDatabaseMapTableCarrier *carrier = [[SJDatabaseMapTableCarrier alloc] initWithClass:cls];
    NSMutableArray<SJDatabaseMapTableCarrier *> *container = [NSMutableArray new];
    [carrier parseCorrespondingKeysAddToContainer:container];
    const char *table_name = sj_table_name(cls);
    NSString *sql_str = [NSString stringWithFormat:@"SELECT *FROM %s WHERE %@=%ld;", table_name, carrier.primaryKeyOrAutoincrementPrimaryKey, (long)primaryValue];
    return sj_value_query(self.database, sql_str.UTF8String, cls, container, nil).firstObject;
}

- (NSArray<id<SJDBMapUseProtocol>> * __nullable)queryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict {
    const char *table_name = sj_table_name(cls);
    NSMutableString *sql_str = [NSMutableString new];
    [sql_str appendFormat:@"SELECT *FROM %s WHERE ", table_name];
    if ( ![dict.allValues.firstObject isKindOfClass:[NSArray class]] ) {
        [dict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [sql_str appendFormat:@"\"%@\" = '%@' AND ", key, sj_value_filter(obj)];
        }];
        [sql_str deleteCharactersInRange:NSMakeRange(sql_str.length - 5, 5)];
        [sql_str appendString:@";"];
    }
    else {
        [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray *values, BOOL * _Nonnull stop) {
            [sql_str appendFormat:@"%@ IN (", key];
            [values enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj = sj_value_filter(obj);
                [sql_str appendFormat:@"'%@',", obj];
            }];
            [sql_str deleteCharactersInRange:NSMakeRange(sql_str.length - 1, 1)];
            [sql_str appendFormat:@") AND "];
        }];
        [sql_str deleteCharactersInRange:NSMakeRange(sql_str.length - 5, 5)];
        [sql_str appendString:@";"];
    }
    return sj_value_query(self.database, sql_str.UTF8String, cls, nil, nil);
}

- (NSArray<id<SJDBMapUseProtocol>> * __nullable)queryDataWithClass:(Class)cls range:(NSRange)range {
    const char *table_name = sj_table_name(cls);
    NSMutableString *sql_str = [NSMutableString new];
    [sql_str appendFormat:@"SELECT * FROM %s LIMIT %ld, %ld;", table_name, (long)range.location, (long)range.length];
    return sj_value_query(self.database, sql_str.UTF8String, cls, nil, nil);
}

- (NSInteger)queryQuantityWithClass:(Class)cls {
    if ( !cls ) return 0;
    NSString *sql_str = [NSString stringWithFormat:@"SELECT count(*) FROM %s;", sj_table_name(cls)];
    return [sj_sql_query(self.database, sql_str.UTF8String, nil).firstObject[@"count(*)"] integerValue];
}

- (NSArray<id<SJDBMapUseProtocol>> * _Nullable)fuzzyQueryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict match:(SJDatabaseMapFuzzyMatch)match {
    if ( !cls ) return nil;
    if ( 0 == dict.count ) return nil;
    
    const char *table_name = sj_table_name(cls);
    NSMutableString *sql_str = [NSMutableString new];
    [sql_str appendFormat:@"SELECT *FROM %s WHERE ", table_name];
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        
        obj = sj_value_filter(obj);
        
        switch (match) {
                //      *  ...A...
            case SJDatabaseMapFuzzyMatchBilateral:
            {
                [sql_str appendFormat:@"%@ LIKE '%%%@%%'", key, obj];
            }
                break;
                //      *  ABC.....
            case SJDatabaseMapFuzzyMatchFront:
            {
                [sql_str appendFormat:@"%@ LIKE '%@%%'", key, obj];
            }
                break;
                //     *  ...DEF
            case SJDatabaseMapFuzzyMatchLater:
            {
                [sql_str appendFormat:@"%@ LIKE '%%%@'", key, obj];
            }
                break;
        }
        
        [sql_str appendString:@" AND "];
    }];
    [sql_str deleteCharactersInRange:NSMakeRange(sql_str.length - 5, 5)];
    [sql_str appendString:@";"];
    return sj_value_query(self.database, sql_str.UTF8String, cls, nil, nil);
}
- (NSArray<id<SJDBMapUseProtocol>> * _Nullable)fuzzyQueryDataWithClass:(Class)cls property:(NSString *)fields part1:(NSString *)part1 part2:(NSString *)part2 {
    if ( !cls ) return nil;
    if ( 0 == fields.length || 0 == part1.length || 0 == part2.length ) return nil;
    const char *table_name = sj_table_name(cls);
    part1 = sj_value_filter(part1);
    part2 = sj_value_filter(part2);
    NSMutableString *sql_str = [NSMutableString new];
    // where name like A%B;
    [sql_str appendFormat:@"SELECT *FROM %s WHERE %@ LIKE '%@%%%@';", table_name, fields, part1, part2];
    return sj_value_query(self.database, sql_str.UTF8String, cls, nil, nil);
}
- (NSArray<id<SJDBMapUseProtocol>> * _Nullable)queryDataWithClass:(Class)cls primaryValues:(NSArray<NSNumber *> *)primaryValues {
    if ( !cls ) return nil;
    if ( primaryValues.count == 0 ) return nil;
    SJDatabaseMapTableCarrier *carrier = [[SJDatabaseMapTableCarrier alloc] initWithClass:cls];
    NSMutableArray<SJDatabaseMapTableCarrier *> *container = [NSMutableArray new];
    [carrier parseCorrespondingKeysAddToContainer:container];
    const char *table_name = sj_table_name(cls);
    NSMutableString *sql_str = [NSMutableString new];
    [sql_str appendFormat:@"SELECT *FROM %s WHERE %@ IN (", table_name, carrier.primaryKeyOrAutoincrementPrimaryKey];
    [primaryValues enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [sql_str appendFormat:@"%ld,", (long)[obj integerValue]];
    }];
    if ( [sql_str hasSuffix:@","] ) [sql_str deleteCharactersInRange:NSMakeRange(sql_str.length - 1, 1)];
    [sql_str appendFormat:@");"];
    return sj_value_query(self.database, sql_str.UTF8String, cls, container, nil);
}
- (NSArray<id<SJDBMapUseProtocol>> * _Nullable)queryDataWithClass:(Class)cls property:(NSString *)property values:(NSArray *)values {
    if ( !cls ) return nil;
    if ( property.length == 0 ) return nil;
    if ( values.count == 0 ) return nil;
    return [self queryDataWithClass:cls queryDict:@{property:values}];
}
- (NSArray<id<SJDBMapUseProtocol>> * _Nullable)sortQueryWithClass:(Class)cls property:(NSString *)property sortType:(SJDatabaseMapSortType)sortType {
    if ( !cls ) return nil;
    if ( 0 == property.length ) return nil;
    
    const char *table_name = sj_table_name(cls);
    NSMutableString *sql_str = [NSMutableString new];
    NSString *sort = nil;
    switch (sortType) {
        case SJDatabaseMapSortType_Asc: {
            sort = @"ASC";
        }
            break;
        case SJDatabaseMapSortType_Desc: {
            sort = @"DESC";
        }
            break;
    }
    [sql_str appendFormat:@"SELECT *FROM %s ORDER BY \"%@\" %@;", table_name, property, sort];
    return sj_value_query(self.database, sql_str.UTF8String, cls, nil, nil);
}
- (NSArray<id<SJDBMapUseProtocol>> * _Nullable)sortQueryWithClass:(Class)cls property:(NSString *)property sortType:(SJDatabaseMapSortType)sortType range:(NSRange)range {
    if ( !cls ) return nil;
    if ( property.length == 0 ) return nil;
    const char *table_name = sj_table_name(cls);
    NSMutableString *sql_str = [NSMutableString new];
    NSString *sort = nil;
    switch (sortType) {
        case SJDatabaseMapSortType_Asc: {
            sort = @"ASC";
        }
            break;
        case SJDatabaseMapSortType_Desc: {
            sort = @"DESC";
        }
            break;
    }
    [sql_str appendFormat:@"SELECT *FROM %s ORDER BY \"%@\" %@ LIMIT %ld, %ld;", table_name, property, sort, (long)range.location, (long)range.length];
    return sj_value_query(self.database, sql_str.UTF8String, cls, nil, nil);
}
- (NSArray<id<SJDBMapUseProtocol>> * _Nullable)sortQueryWithClass:(Class)cls queryDict:(NSDictionary *)quertyDict sortField:(NSString *)sortField sortType:(SJDatabaseMapSortType)sortType {
    if ( !cls ) return nil;
    if ( quertyDict.count == 0 ) return nil;
    
    const char *table_name = sj_table_name(cls);
    NSString *sort = nil;
    switch (sortType) {
        case SJDatabaseMapSortType_Asc: {
            sort = @"ASC";
        }
            break;
        case SJDatabaseMapSortType_Desc: {
            sort = @"DESC";
        }
            break;
    }
    
    NSMutableString *where = [NSMutableString stringWithFormat:@"WHERE "];
    [quertyDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [where appendFormat:@"\"%@\" = '%@' and ", key, sj_value_filter(obj)];
    }];
    [where deleteCharactersInRange:NSMakeRange(where.length - 5, 5)];
    NSString *sql_str = [NSString stringWithFormat:@"SELECT *FROM %s %@ ORDER BY \"%@\" %@;", table_name, where, sortField, sort];
    return sj_value_query(self.database, sql_str.UTF8String, cls, nil, nil);
}
@end
