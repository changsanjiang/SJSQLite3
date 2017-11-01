//
//  SJDatabaseMap+RealTime.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/11/1.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SJDatabaseMap+RealTime.h"
#import <objc/message.h>
#import "SJDatabaseMap+GetInfo.h"

#import "SJDBMapUnderstandingModel.h"
#import "SJDBMapPrimaryKeyModel.h"
#import "SJDBMapAutoincrementPrimaryKeyModel.h"
#import "SJDBMapCorrespondingKeyModel.h"
#import "SJDBMapArrayCorrespondingKeysModel.h"
#import "SJDBMapQueryCache.h"


#define _SJLog


@implementation SJDatabaseMap (RealTime)

/*!
 *  执行SQL语句
 */
- (void)_sjExeSQL:(const char *)sql completeBlock:(void(^)(BOOL r))block {
    char *error = NULL;
    BOOL r = (SQLITE_OK == sqlite3_exec(self.sqDB, sql, NULL, NULL, &error));
    if ( block ) block(r);
    if ( error != NULL ) {
        NSLog(@"SJDatabaseMap Error ==> \n SQL  : %s\n Error: %s", sql, error);
        sqlite3_free(error);
    }
}

/*!
 *  创建或更新一张表
 */
- (BOOL)_sjCreateOrAlterTabWithClass:(Class)cls {
    
    /*!
     *  如果表不存在创建表
     */
    NSMutableSet<NSString *> *fieldsSet = [self _sjQueryTabAllFields_Set_WithClass:cls];
    if ( !fieldsSet ) {return [self _sjCreateTab:cls];}
    
    /*!
     *  如果表存在, 查看是否有更新字段
     */
    NSArray<SJDBMapCorrespondingKeyModel *> *cMs = [self sjGetCorrespondingKeys:cls];
    NSMutableSet<NSString *> *ivarNamesSet = _sjGetIvarNames(cls);
    
    NSMutableSet<NSString *> *objFields = [NSMutableSet new];
    [ivarNamesSet enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        /*!
         *  遍历去掉下划线
         */
        [objFields addObject:[obj substringFromIndex:1]];
    }];
    
    /*!
     *  获取两个集合不同的键
     */
    [objFields minusSet:fieldsSet];
    
    if ( !objFields.count ) return YES;
    
    __block BOOL exeSQLResultBol = YES;
    
    [objFields enumerateObjectsUsingBlock:^(NSString * _Nonnull objF, BOOL * _Nonnull stop) {
        const char *tabName = [self sjGetTabName:cls];
        __block const char *fields = NULL;
        __block const char *dbType = NULL;
        
        __block BOOL containerBol = NO;
        [cMs enumerateObjectsUsingBlock:^(SJDBMapCorrespondingKeyModel * _Nonnull cM, NSUInteger idx, BOOL * _Nonnull stop) {
            if ( ![objF isEqualToString:cM.ownerFields] ) return;
            
            if ( [fieldsSet containsObject:cM.correspondingFields] ) containerBol = YES;
            else {
                fields = cM.correspondingFields.UTF8String;
                dbType = "INTEGER";
            }
            *stop = YES;
        }];
        
        if ( containerBol ) return;
        
        if ( NULL == fields) {
            fields = objF.UTF8String;
            dbType = _sjGetDatabaseIvarType(cls, [NSString stringWithFormat:@"_%@", objF].UTF8String);
        }
        
        NSString *sql = [NSString stringWithFormat:@"ALTER TABLE '%s' ADD '%s' %s;", tabName, fields, dbType];
        
        [self _sjExeSQL:sql.UTF8String completeBlock:^(BOOL result) {
            if ( !result ) {
                NSLog(@"[%@] 添加字段[%@]失败", cls, objF);
                exeSQLResultBol = NO;
            }
        }];
        
#ifdef _SJLog
        NSLog(@"%@", sql);
#endif
    }];
    return exeSQLResultBol;
}

/*!
 *  自动创建相关的表
 */
- (BOOL)_sjAutoCreateOrAlterRelevanceTabWithClass:(Class)cls {
    __block BOOL result = YES;
    [[self sjGetRelevanceClasses:cls] enumerateObjectsUsingBlock:^(Class  _Nonnull relevanceCls, BOOL * _Nonnull stop) {
        result = [self _sjCreateOrAlterTabWithClass:relevanceCls];
        if ( result ) return;
        result = NO;
        *stop = YES;
    }];
    return result;
}


// select name from sqlite_master;
- (NSMutableSet<NSString *> *)_sjQueryTabAllFields_Set_WithClass:(Class)cls {
    NSString *sql = [NSString stringWithFormat:@"PRAGMA  table_info('%s');", [self sjGetTabName:cls]];
    NSMutableSet<NSString *> *dbFields = [NSMutableSet new];
    [[self _sjQueryWithSQLStr:sql] enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [dbFields addObject:obj[@"name"]];
    }];
    if ( 0 == dbFields.count ) return NULL;
    return dbFields;
}

/*!
 *  整理模型数据
 */
- (NSDictionary<NSString *, NSArray<id<SJDBMapUseProtocol>> *> *)_sjPutInOrderModels:(NSArray<id> *)models {
    NSMutableDictionary<NSString *, NSMutableArray<id> *> *modelsDictM = [NSMutableDictionary new];
    [models enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *tabName = NSStringFromClass([obj class]);
        if ( !modelsDictM[tabName] ) modelsDictM[tabName] = [NSMutableArray new];
        [modelsDictM[tabName] addObject:obj];
    }];
    return modelsDictM;
}

- (NSDictionary<NSString *, NSArray<id<SJDBMapUseProtocol>> *> *)_sjPutInOrderModelsSet:(NSSet<id> *)models {
    NSMutableDictionary<NSString *, NSMutableArray<id> *> *modelsDictM = [NSMutableDictionary new];
    [models enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *tabName = NSStringFromClass([obj class]);
        if ( !modelsDictM[tabName] ) modelsDictM[tabName] = [NSMutableArray new];
        [modelsDictM[tabName] addObject:obj];
    }];
    return modelsDictM;
    
}

/*!
 *  根据条件模糊查询
 */
- (NSArray<id<SJDBMapUseProtocol>> *)_sjFuzzyQueryConversionMolding:(Class)cls match:(SJDatabaseMapFuzzyMatch)match dict:(NSDictionary *)dict {
    SJDBMapUnderstandingModel *uM = [self sjGetUnderstandingWithClass:cls];
    if ( !uM.primaryKey && !uM.autoincrementPrimaryKey ) return nil;
    NSAssert(uM.primaryKey || uM.autoincrementPrimaryKey, @"[%@] 该类没有设置主键", cls);
    
    const char *tabName = [self sjGetTabName:cls];
    
    NSMutableString *fieldsSqlM = [NSMutableString new];
    [fieldsSqlM appendFormat:@"select * from %s where ", tabName];
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        
        obj = [self filterValue:obj];
        
        switch (match) {
                //      *  ...A...
            case SJDatabaseMapFuzzyMatchAll:
            {
                [fieldsSqlM appendFormat:@"%@ like '%%%@%%'", key, obj];
            }
                break;
                //      *  ABC.....
            case SJDatabaseMapFuzzyMatchFront:
            {
                [fieldsSqlM appendFormat:@"%@ like '%@%%'", key, obj];
            }
                break;
                //     *  ...DEF
            case SJDatabaseMapFuzzyMatchLater:
            {
                [fieldsSqlM appendFormat:@"%@ like '%%%@'", key, obj];
            }
                break;
            default:
                break;
        }
        
        [fieldsSqlM appendString:@" and "];
    }];
    [fieldsSqlM deleteCharactersInRange:NSMakeRange(fieldsSqlM.length - 5, 5)];
    [fieldsSqlM appendString:@";"];
    
    NSMutableArray<NSMutableDictionary *> *incompleteData = [NSMutableArray new];
    [[self _sjQueryWithSQLStr:fieldsSqlM] enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [incompleteData addObject:obj.mutableCopy];
    }];
    
    return [self _sjConversionMolding:cls rawStorageData:incompleteData memeryCache:[SJDBMapQueryCache new]];
}


- (NSArray<id> *)_sjConversionMolding:(Class)cls rawStorageData:(NSArray<NSDictionary *> *)rawStorageData memeryCache:(SJDBMapQueryCache *)cache {
    NSMutableArray<id> *allDataModel = [NSMutableArray new];
    NSArray<SJDBMapCorrespondingKeyModel *>*cKr = [self sjGetCorrespondingKeys:cls];
    NSArray<SJDBMapArrayCorrespondingKeysModel *> *aKr = [self sjGetArrayCorrespondingKeys:cls];
    [rawStorageData enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
        id model = [cls new];
        [self _sjConversionModelWithOwnerModel:model dict:dict cKr:cKr aKr:aKr memeryCache:cache];
        [allDataModel addObject:model];
    }];
    if ( 0 == allDataModel.count ) return nil;
    return allDataModel;
}

/*!
 *  查询数据库原始存储数据
 */
- (NSArray<NSDictionary *> *)_sjQueryRawStorageData:(Class)cls {
    const char *tabName = [self sjGetTabName:cls];
    NSString *sql = [NSString stringWithFormat:@"select *from %s;", tabName];
    
    NSMutableArray<NSMutableDictionary *> *incompleteData = [NSMutableArray new];
    [[self _sjQueryWithSQLStr:sql] enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [incompleteData addObject:obj.mutableCopy];
    }];
    return incompleteData;
}

/*!
 *  查询数据库原始存储数据
 */
- (NSDictionary *)_sjQueryRawStorageData:(Class)cls primaryValue:(NSInteger)primaryValue {
    SJDBMapUnderstandingModel *uM = [self sjGetUnderstandingWithClass:cls];
    NSAssert(uM.primaryKey || uM.autoincrementPrimaryKey, @"[%@] 该类没有设置主键", cls);
    const char *tabName = [self sjGetTabName:cls];
    NSString *fields = uM.primaryKey ? uM.primaryKey.ownerFields : uM.autoincrementPrimaryKey.ownerFields;
    NSString *sql = [NSString stringWithFormat:@"select * from %s where %@ = %zd;", tabName, fields, primaryValue];
    return [self _sjQueryWithSQLStr:sql].firstObject;
}

- (id<SJDBMapUseProtocol>)_sjQueryCached:(SJDBMapQueryCache *)cache cPV:(NSInteger)cPrimaryValue cCN:(NSString *)corClassName {
    __block id<SJDBMapUseProtocol> cacheModel = nil;
    // query cache.
    [cache.modelCacheM enumerateObjectsUsingBlock:^(SJDBMapModelCache * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ( ![obj.className isEqualToString:corClassName] ) return;
        [obj.memeryM enumerateObjectsUsingBlock:^(id<SJDBMapUseProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSInteger cacheKeyValue = [[self sjGetPrimaryOrAutoPrimaryValue:obj] integerValue];
            if ( cacheKeyValue != cPrimaryValue ) return;
            cacheModel = obj;
            *stop = YES;
        }];
    }];
    return cacheModel;
}

- (Class)_sjTargetClass:(id<SJDBMapUseProtocol>)target {
    return [(id)target class];
}

- (void)_sjAddToQueryCache:(SJDBMapQueryCache *)cache target:(id<SJDBMapUseProtocol>)target {
    if ( !target ) return;
    NSString *clsName = NSStringFromClass([self _sjTargetClass:target]);
    __block BOOL added = NO;
    [cache.modelCacheM enumerateObjectsUsingBlock:^(SJDBMapModelCache * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ( ![obj.className isEqualToString:clsName] ) return ;
        [obj.memeryM addObject:target];
        added = YES;
        *stop = YES;
    }];
    
    if ( added ) return;
    
    SJDBMapModelCache *obj = [SJDBMapModelCache new];
    obj.className = clsName;
    [obj.memeryM addObject:target];
    [cache.modelCacheM addObject:obj];
}


- (void)_sjConversionModelWithOwnerModel:(id)model dict:(NSDictionary *)dict cKr:(NSArray<SJDBMapCorrespondingKeyModel *>*)cKr aKr:(NSArray<SJDBMapArrayCorrespondingKeysModel *> *)aKr memeryCache:(SJDBMapQueryCache *)cache {
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull fields, id  _Nonnull fieldsValue, BOOL * _Nonnull stop) {
        __block BOOL continueBool = NO;
        [cKr enumerateObjectsUsingBlock:^(SJDBMapCorrespondingKeyModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            // is cor
            if ( [fields isEqualToString:obj.correspondingFields] ) {
                NSInteger cPrimaryValue = [fieldsValue integerValue];
                
                NSString *corClassName = NSStringFromClass(obj.correspondingCls);
                id cmodel = [self _sjQueryCached:cache cPV:cPrimaryValue cCN:corClassName];
                
                if ( cmodel )  {
                    [model setValue:cmodel forKey:obj.ownerFields];
                    continueBool = YES;
                    *stop = YES;
                    return;
                }
                
                cmodel = [obj.correspondingCls new];
                NSArray<SJDBMapCorrespondingKeyModel *>*ccKr = [self sjGetCorrespondingKeys:obj.correspondingCls];
                NSArray<SJDBMapArrayCorrespondingKeysModel *> *caKr = [self sjGetArrayCorrespondingKeys:obj.correspondingCls];
                [self _sjConversionModelWithOwnerModel:cmodel dict:[self _sjQueryRawStorageData:obj.correspondingCls primaryValue:cPrimaryValue] cKr:ccKr aKr:caKr memeryCache:cache];
                [self _sjAddToQueryCache:cache target:cmodel];
                [model setValue:cmodel forKey:obj.ownerFields];
                continueBool = YES;
                *stop = YES;
            }
        }];
        
        if ( continueBool ) return;
        
        [aKr enumerateObjectsUsingBlock:^(SJDBMapArrayCorrespondingKeysModel * _Nonnull ACKM, NSUInteger idx, BOOL * _Nonnull stop) {
            
            // is arr
            if ( [fields isEqualToString:ACKM.ownerFields] ) {
                NSData *data = [fieldsValue dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary<NSString *, NSArray<NSNumber *> *> *aPrimaryValues = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                [aPrimaryValues enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull clsName, NSArray<NSNumber *> * _Nonnull aPVlues, BOOL * _Nonnull stop) {
                    NSMutableArray<id> *ar = [NSMutableArray new];
                    [aPVlues enumerateObjectsUsingBlock:^(NSNumber * _Nonnull value, NSUInteger idx, BOOL * _Nonnull stop) {
                        id amodel = [self _sjQueryCached:cache cPV:[value integerValue] cCN:NSStringFromClass(ACKM.correspondingCls)];
                        if ( !amodel ) {
                            amodel = [ACKM.correspondingCls new];
                            NSArray<SJDBMapCorrespondingKeyModel *>*ccKr = [self sjGetCorrespondingKeys:ACKM.correspondingCls];
                            NSArray<SJDBMapArrayCorrespondingKeysModel *> *caKr = [self sjGetArrayCorrespondingKeys:ACKM.correspondingCls];
                            [self _sjConversionModelWithOwnerModel:amodel dict:[self _sjQueryRawStorageData:ACKM.correspondingCls primaryValue:[value integerValue]] cKr:ccKr aKr:caKr memeryCache:cache];
                            [self _sjAddToQueryCache:cache target:amodel];
                        }
                        [ar addObject:amodel];
                    }];
                    [model setValue:ar forKey:ACKM.ownerFields];
                }];
                continueBool = YES;
                *stop = YES;
            }
        }];
        
        if ( continueBool ) return;
        
        // is common
        if ( [model respondsToSelector:NSSelectorFromString(fields)] ) {
            [model setValue:fieldsValue forKey:fields];
        }
    }];
}

/*!
 *  插入
 */
- (BOOL)_sjInsertOrUpdateDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models enableTransaction:(BOOL)enableTransaction {
    __block BOOL result = YES;
    if ( enableTransaction ) [self _sjBeginTransaction];
    
    __block SJDBMapUnderstandingModel *uM;
    NSMutableSet<id<SJDBMapUseProtocol>> *modelsSetM = [NSMutableSet new];
    [models enumerateObjectsUsingBlock:^(id<SJDBMapUseProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // 获取所有相关的模型数据
        NSMutableSet<id<SJDBMapUseProtocol>> *set = [self sjGetRelevanceObjs:obj];
        if ( set ) [modelsSetM unionSet:set];
    }];
    
    // 归类整理
    NSMutableSet<id<SJDBMapUseProtocol>> *hasPrimaryKeyModelsSetM = [NSMutableSet new];
    NSMutableSet<id<SJDBMapUseProtocol>> *hasAutoPrimaryKeyModelsSetM = [NSMutableSet new];
    
    NSDictionary<NSString *, NSArray<id> *> *putInOrderResult = [self _sjPutInOrderModelsSet:modelsSetM];
    [putInOrderResult.allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull clsStr, NSUInteger idx, BOOL * _Nonnull stop) {
        Class cls = NSClassFromString(clsStr);
        BOOL hasPrimaryKey = [self sjHasPrimaryKey:cls];
        BOOL hasAutoPrimaryKey = [self sjHasAutoPrimaryKey:cls];
        if ( hasPrimaryKey ) [hasPrimaryKeyModelsSetM addObjectsFromArray:putInOrderResult[clsStr]];
        else if ( hasAutoPrimaryKey ) [hasAutoPrimaryKeyModelsSetM addObjectsFromArray:putInOrderResult[clsStr]];
        NSAssert(hasPrimaryKey || hasAutoPrimaryKey , @"%@ - 该类没有实现主键或自增主键.", cls);
    }];
    
    // 优先 插入自增主键类
    [hasAutoPrimaryKeyModelsSetM enumerateObjectsUsingBlock:^(id<SJDBMapUseProtocol>  _Nonnull model, BOOL * _Nonnull stop) {
        Class cls = [self _sjTargetClass:model];
        if ( cls != uM.ownerCls ) uM = [self sjGetUnderstandingWithClass:cls];
        result = [self _sjInsertOrUpdateDataWithModel:model uM:uM];
        if ( !result ) *stop = YES;
    }];
    
    if ( result ) {
        // 插入 主键类
        [hasPrimaryKeyModelsSetM enumerateObjectsUsingBlock:^(id<SJDBMapUseProtocol>  _Nonnull model, BOOL * _Nonnull stop) {
            Class cls = [self _sjTargetClass:model];
            if ( cls != uM.ownerCls ) uM = [self sjGetUnderstandingWithClass:cls];
            result = [self _sjInsertOrUpdateDataWithModel:model uM:uM];
            if ( !result ) *stop = YES;
        }];
    }
    
    if ( enableTransaction ) [self _sjCommitTransaction];
    return result;
}

- (BOOL)_sjInsertOrUpdateDataWithModel:(id<SJDBMapUseProtocol>)obj uM:(SJDBMapUnderstandingModel *)uM {
    __block BOOL result = YES;
    NSString *prefixSQL  = [self sjGetInsertOrUpdatePrefixSQL:uM];
    NSString *subffixSQL = [self sjGetInsertOrUpdateSuffixSQL:obj];
    NSString *sql = [NSString stringWithFormat:@"%@ %@;", prefixSQL, subffixSQL];
    
    [self _sjExeSQL:sql.UTF8String completeBlock:^(BOOL r) {
        if ( !r ) {
            result = NO;
            NSLog(@"[%@] 插入或更新失败", obj);
        }
        Class cls = [self _sjTargetClass:obj];
        SJDBMapAutoincrementPrimaryKeyModel *aPKM = [self sjGetAutoincrementPrimaryKey:cls];
        if ( !aPKM ) return;
        id aPKV = [(id)obj valueForKey:aPKM.ownerFields];
        if ( 0 != [aPKV integerValue] ) return;
        aPKV = [self _sjGetLastDataIDWithClass:cls autoincrementPrimaryKeyModel:aPKM];
        if ( !aPKV ) return;
        /*!
         *  如果是自增主键, 在模型自增主键为0的情况下, 插入完数据后, 为这个模型的自增主键赋值. 防止重复插入. */
        [(id)obj setValue:aPKV forKey:aPKM.ownerFields];
    }];
    return result;
}

/*!
 *  获取自增键最后一个ID. 根据ID排序, 获取最后一条数据的ID
 */
- (NSNumber *)_sjGetLastDataIDWithClass:(Class)cls autoincrementPrimaryKeyModel:(SJDBMapAutoincrementPrimaryKeyModel *)aPKM {
    NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM %s ORDER by %@ desc limit 1;", aPKM.ownerFields, [self sjGetTabName:cls], aPKM.ownerFields];
    NSDictionary *dict = [self _sjQueryWithSQLStr:sql].firstObject;
    if ( !dict && !dict.count ) return nil;
    NSString *fields = [self sjGetAutoPrimaryFields:cls];
    if ( 0 == fields.length ) return nil;
    return dict[fields];
}

- (void)_sjBeginTransaction {
    sqlite3_exec(self.sqDB, "begin", 0, 0, 0);
}

- (void)_sjCommitTransaction {
    sqlite3_exec(self.sqDB, "commit", 0, 0, 0);
}

/*!
 *  更新
 */
- (BOOL)_sjUpdate:(id<SJDBMapUseProtocol>)model property:(NSArray<NSString *> *)fields {
    __block BOOL result = YES;
    
    [self _sjBeginTransaction];
    
    [self _sjCreateOrAlterTabWithClass:[self _sjTargetClass:model]];
    
    // 查看是否有特殊字段
    NSDictionary<NSString *, NSArray<NSString *> *> *putInOrderResult = [self _sjPutInOrderModel:model fields:fields];
    
    // 存放普通字段
    NSArray<NSString *> *commonFields = putInOrderResult[@"commonFields"];
    
    // 存放独特字段
    NSArray<NSString *> *uniqueFields = putInOrderResult[@"uniqueFields"];
    
    // 先处理普通字段, 再处理特殊字段
    if ( 0 != commonFields.count ) {
        result = [self _sjUpdate:model commonFields:commonFields];
    }
    
    if ( result && 0 != uniqueFields.count ) {
        result = [self _sjUpdate:model uniqueFields:uniqueFields];
    }
    [self _sjCommitTransaction];
    return result;
}

- (BOOL)_sjUpdate:(id<SJDBMapUseProtocol>)model commonFields:(NSArray<NSString *> *)fiedls {
    NSString *sql = [self sjGetCommonUpdateSQLWithFields:fiedls model:model];
    __block BOOL result = YES;
    [self _sjExeSQL:sql.UTF8String completeBlock:^(BOOL r) {
        if ( !r ) {
            result = NO;
            NSLog(@"[%@]- %@ 插入或更新失败", model, sql);
        }
    }];
    return result;
}

- (BOOL)_sjUpdate:(id<SJDBMapUseProtocol>)model uniqueFields:(NSArray<NSString *> *)uniqueFields {
    __block BOOL result = YES;
    // Update model
    result = [self _sjInsertOrUpdateDataWithModel:model uM:[self sjGetUnderstandingWithClass:[self _sjTargetClass:model]]];
    
    if ( !result ) return NO;
    
    // insert values
    [uniqueFields enumerateObjectsUsingBlock:^(NSString * _Nonnull fields, NSUInteger idx, BOOL * _Nonnull stop) {
        id uniqueValue = [(id)model valueForKey:fields];
        // is Arr
        if ( [uniqueValue isKindOfClass:[NSArray class]] ) {
            // insert arr values
            [self _sjCreateOrAlterTabWithClass:[[uniqueValue firstObject] class]];
            result = [self _sjInsertOrUpdateDataWithModels:uniqueValue enableTransaction:NO];
            return;
        }
        // is cor
        [self _sjCreateOrAlterTabWithClass:[uniqueValue class]];
        if ( result ) result = [self _sjInsertOrUpdateDataWithModel:uniqueValue uM:[self sjGetUnderstandingWithClass:[uniqueValue class]]];
    }];
    
    return result;
}

/*!
 *  Possible keys ..
 *  1. commonFields
 *  2. uniqueFields
 */
- (NSDictionary<NSString *, NSArray<NSString *> *> *)_sjPutInOrderModel:(id<SJDBMapUseProtocol>)model fields:(NSArray<NSString *> *)fields {
    // 查看是否有特殊字段
    
    // 存放普通字段
    NSMutableArray<NSString *> *commonFields = [NSMutableArray new];
    
    // 存放独特字段
    NSMutableArray<NSString *> *uniqueFields = [NSMutableArray new];
    
    /*!
     *  可能的特殊字段
     *  1. 相应键
     *  2. 数组相应键
     */
    Class cls = [self _sjTargetClass:model];
    NSArray<NSString *> *corOriginFields = [self sjGetCorrespondingOriginFields:cls];
    
    NSArray<NSString *> *arrCorOriginFields = [self sjGetArrCorrespondingOriginFields:cls];
    
    // 搜索特殊字段
    [fields enumerateObjectsUsingBlock:^(NSString * _Nonnull outObj, NSUInteger idx, BOOL * _Nonnull stop) {
        __block BOOL addedBol = NO;
        [corOriginFields enumerateObjectsUsingBlock:^(NSString * _Nonnull inObj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ( [outObj isEqualToString:inObj] ) { [uniqueFields addObject:inObj]; addedBol = YES;}
        }];
        [arrCorOriginFields enumerateObjectsUsingBlock:^(NSString * _Nonnull inObj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ( [outObj isEqualToString:inObj] ) { [uniqueFields addObject:inObj]; addedBol = YES;}
        }];
        if ( !addedBol ) [commonFields addObject:outObj];
    }];
    
    NSMutableDictionary<NSString *, NSArray<NSString *> *> *dictM = [NSMutableDictionary new];
    if ( 0 != commonFields.count ) [dictM setObject:commonFields forKey:@"commonFields"];
    if ( 0 != uniqueFields.count ) [dictM setObject:uniqueFields forKey:@"uniqueFields"];
    return dictM;
}

- (BOOL)_sjUpdate:(id<SJDBMapUseProtocol>)model insertedOrUpdatedValues:(NSDictionary<NSString *, id> *)insertedOrUpdatedValues {
    if ( 0 == insertedOrUpdatedValues.allValues ) return YES;
    
    [self _sjBeginTransaction];
    
    __block BOOL result = YES;
    // 查看是否有特殊字段
    NSDictionary<NSString *, NSArray<NSString *> *> *putInOrderResult = [self _sjPutInOrderModel:model fields:insertedOrUpdatedValues.allKeys];
    
    // 存放普通字段
    NSArray<NSString *> *commonFields = putInOrderResult[@"commonFields"];
    
    // 存放独特字段
    NSArray<NSString *> *uniqueFields = putInOrderResult[@"uniqueFields"];
    
    // 先处理普通字段, 再处理特殊字段
    
    if ( 0 != commonFields.count ) {
        result = [self _sjUpdate:model commonFields:commonFields];
    }
    
    if ( result && 0 != uniqueFields.count ) {
        // 特殊字段
        [uniqueFields enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            id uniqueValue = [(id)model valueForKey:obj];
            // is Arr
            if ( [uniqueValue isKindOfClass:[NSArray class]] ) {
                [self _sjCreateOrAlterTabWithClass:[[uniqueValue firstObject] class]];
                result = [self _sjInsertOrUpdateDataWithModels:uniqueValue enableTransaction:NO];
                if ( !result ) { *stop = YES;}
                return;
            }
            // is cor
            SJDBMapUnderstandingModel *uM = [self sjGetUnderstandingWithClass:[uniqueValue class]];
            [self _sjCreateOrAlterTabWithClass:uniqueValue];
            result = [self _sjInsertOrUpdateDataWithModel:uniqueValue uM:uM];
            if ( !result ) { *stop = YES;}
        }];
    }
    // update
    result = [self _sjInsertOrUpdateDataWithModel:model uM:[self sjGetUnderstandingWithClass:[self _sjTargetClass:model]]];
    
    [self _sjCommitTransaction];
    
    return result;
}

/*!
 *  获取主键值
 */
- (NSArray<NSNumber *> *)_sjGetPrimaryValues:(NSArray<id<SJDBMapUseProtocol>> *)models {
    if ( !models.count ) return nil;
    NSString *primaryFields = [self sjGetPrimaryKey:[self _sjTargetClass:models[0]]].ownerFields;
    if ( !primaryFields ) return nil;
    NSMutableArray<NSNumber *> * primaryValuesM = [NSMutableArray new];
    [models enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [primaryValuesM addObject:[obj valueForKey:primaryFields]];
    }];
    return primaryValuesM;
}

/*!
 *  创建表
 */
- (BOOL)_sjCreateTab:(Class)cls {
    
    if ( !cls ) { return NO;}
    
    SJDBMapUnderstandingModel *uM = [self sjGetUnderstandingWithClass:cls];
    
    NSAssert(uM.primaryKey || uM.autoincrementPrimaryKey, @"[%@] 需要一个主键.", cls);
    
    // 获取表名称
    const char *tabName = [self sjGetTabName:cls];
    
    // SQ语句
    char *sql = malloc(1024);
    *sql = '\0';
    _sjmystrcat(sql, "CREATE TABLE IF NOT EXISTS");
    _sjmystrcat(sql, " ");
    _sjmystrcat(sql, tabName);
    _sjmystrcat(sql, " ");
    _sjmystrcat(sql, "(");
    
    unsigned int ivarCount = 0;
    __block struct objc_ivar **ivarList = class_copyIvarList(cls, &ivarCount);
    
    for (int i = 0; i < ivarCount; i ++) {
        char *ivarName = (char *)ivar_getName(ivarList[i]);
        
        char *field = &ivarName[1];
        char *fieldType = _sjGetDatabaseIvarType(cls, ivarName);
        
        // 提取相应字段(如果有)
        __block SJDBMapCorrespondingKeyModel *correspondingKeyModel = nil;
        [uM.correspondingKeys enumerateObjectsUsingBlock:^(SJDBMapCorrespondingKeyModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ( 0 == strcmp(field, obj.ownerFields.UTF8String) ) {correspondingKeyModel = obj; *stop = YES;};
        }];
        
        if ( correspondingKeyModel ) {
            field = (char *)(correspondingKeyModel.correspondingFields.UTF8String);
            fieldType = "INTEGER";
        }
        
        // 如果字段类型未知, 目前跳过该字段
        if ( 0 == strlen(fieldType) ) continue;
        
        char *fieldSql = malloc(256);
        
        _sjmystrcat(fieldSql, " '");
        _sjmystrcat(fieldSql, field);
        _sjmystrcat(fieldSql, "' ");
        _sjmystrcat(fieldSql, fieldType);
        
        if ( NULL != strstr(sql, fieldSql) ) {free(fieldSql); continue;}
        
        _sjmystrcat(sql, fieldSql);
        free(fieldSql);
        
        // 如果是自增主键
        if      ( NULL != uM.autoincrementPrimaryKey &&
                 0 == strcmp(field, uM.autoincrementPrimaryKey.ownerFields.UTF8String) )
            _sjmystrcat(sql, " PRIMARY KEY AUTOINCREMENT");
        // 如果是主键
        else if ( NULL != uM.primaryKey &&
                 0 == strcmp(field, uM.primaryKey.ownerFields.UTF8String) )
            _sjmystrcat(sql, " PRIMARY KEY");
        
        _sjmystrcat(sql, ",");
    }
    
    size_t length = strlen(sql);
    char lastChar = sql[length - 1];
    if ( lastChar == ',' ) sql[length - 1] = '\0';
    
    _sjmystrcat(sql, ");");
    
#ifdef _SJLog
    NSLog(@"%s", sql);
#endif
    
    __block BOOL createResult = YES;
    [self _sjExeSQL:sql completeBlock:^(BOOL result) {
        createResult = result;
        if ( !result ) {
            NSLog(@"[%@] 创建表失败", cls);
            return;
        }
    }];
    
    free(sql);
    free(ivarList);
    
    sql = NULL;
    ivarList = NULL;
    
    return createResult;
}

- (BOOL)_sjIsUniqueKeyWithKeys:(NSArray<NSString *> *)uniqueKeys target:(const char *)target {
    __block BOOL result = NO;
    [uniqueKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ( 0 != strcmp(obj.UTF8String, target) ) return ;
        result = YES;
        *stop = NO;
    }];
    return result;
}

/*!
 *  向一个表中新增字段
 */
- (BOOL)_sjAlterFields:(Class)cls fields:(NSArray<NSString *> *)fields {
    if ( 0 == fields.count ) return YES;
    __block BOOL result = YES;
    [fields enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *sql = [NSString stringWithFormat:@"ALTER TABLE '%s' ADD '%@' %s;", [self sjGetTabName:cls], obj, _sjGetDatabaseIvarType(cls, [NSString stringWithFormat:@"_%@", obj].UTF8String)];
        [self _sjExeSQL:sql.UTF8String completeBlock:^(BOOL r) {
            if ( !r ) {
                NSLog(@"[%@] 添加字段[%@]失败", cls, obj);
                result = NO;
            }
        }];
        
#ifdef _SJLog
        NSLog(@"%@", sql);
#endif
    }];
    return result;
}

/*!
 *  查
 */
- (NSArray<NSDictionary *> *)_sjQueryWithSQLStr:(NSString *)sqlStr {
    
    sqlite3_stmt *pstmt;
    int result = sqlite3_prepare_v2(self.sqDB, sqlStr.UTF8String, -1, &pstmt, NULL);
    
    NSArray <NSDictionary *> *dataArr = nil;
    
    if (SQLITE_OK == result) dataArr = [self _sjGetTabDataWithStmt:pstmt];
    
    sqlite3_finalize(pstmt);
    
    return dataArr;
}

- (NSArray <NSDictionary *> *)_sjGetTabDataWithStmt:(sqlite3_stmt *)stmt {
    NSMutableArray *dataArrM = [[NSMutableArray alloc] init];
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        NSMutableDictionary *mDict = [NSMutableDictionary dictionary];
        int columnCount = sqlite3_column_count(stmt);
        for ( int i = 0; i < columnCount ; i ++ ) {
            const char *name = sqlite3_column_name(stmt, i);
            NSString *nameKey = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
            int type = sqlite3_column_type(stmt, i);
            switch (type) {
                case SQLITE_INTEGER:
                {
                    int value = sqlite3_column_int(stmt, i);
                    mDict[nameKey] = [NSNumber numberWithInt:value];
                }
                    break;
                case SQLITE_TEXT:
                {
                    const  char *value = (const  char *)sqlite3_column_text(stmt, i);
                    mDict[nameKey] = [NSString stringWithUTF8String:value];
                }
                    break;
                case SQLITE_FLOAT:
                {
                    double value = sqlite3_column_double(stmt, i);
                    mDict[nameKey] = [NSNumber numberWithDouble:value];
                }
                    break;
                default:
                    break;
            }
        }
        [dataArrM addObject:mDict.copy];
    }
    return dataArrM.copy;
}

/*!
 *  拼接字符串
 */
extern char *_sjmystrcat(char *dst, const char *src) {
    char *p = dst;
    while( *p != '\0' ) p++;
    while( *src != '\0' ) *p++ = *src++;
    *p = '\0';
    return p;
}

static char *_sjGetDatabaseIvarType(Class cls, const char *ivarName) {
    Ivar iv = class_getInstanceVariable(cls, ivarName);
    const char *type = ivar_getTypeEncoding(iv);
    //    NSLog(@"%s", type);
    char first = type[0];
    if      ( first == _C_ID )
        return _sjGetDatabaseObjType(type);                // MARK:   #define _C_ID       '@'
    else if ( first == _C_CLASS ) return "";            // MARK:   #define _C_CLASS    '#'
    else if ( first == _C_SEL ) return "TEXT";          // MARK:   #define _C_SEL      ':'
    else if ( first == _C_CHR ) return "TEXT";          // MARK:   #define _C_CHR      'c'
    else if ( first == _C_UCHR ) return "TEXT";         // MARK:   #define _C_UCHR     'C'
    else if ( first == _C_SHT ) return "INTEGER";       // MARK:   #define _C_SHT      's'
    else if ( first == _C_USHT ) return "INTEGER";      // MARK:   #define _C_USHT     'S'
    else if ( first == _C_INT ) return "INTEGER";       // MARK:   #define _C_INT      'i'
    else if ( first == _C_UINT ) return "INTEGER";      // MARK:   #define _C_UINT     'I'
    else if ( first == _C_LNG ) return "";      // MARK:   #define _C_LNG      'l'
    else if ( first == _C_ULNG ) return "";     // MARK:   #define _C_ULNG     'L'
    else if ( first == _C_LNG_LNG ) return "INTEGER";   // MARK:   #define _C_LNG_LNG  'q'
    else if ( first == _C_ULNG_LNG ) return "INTEGER";  // MARK:   #define _C_ULNG_LNG 'Q'
    else if ( first == _C_FLT ) return "REAL";          // MARK:   #define _C_FLT      'f'
    else if ( first == _C_DBL ) return "REAL";          // MARK:   #define _C_DBL      'd'
    else if ( first == _C_BFLD ) return "";     // MARK:   #define _C_BFLD     'b'
    else if ( first == _C_BOOL ) return "INTEGER";      // MARK:   #define _C_BOOL     'B'
    else if ( first == _C_VOID ) return "";     // MARK:   #define _C_VOID     'v'
    else if ( first == _C_UNDEF ) return "";    // MARK:   #define _C_UNDEF    '?'
    else if ( first == _C_PTR ) return "";      // MARK:   #define _C_PTR      '^'
    else if ( first == _C_CHARPTR ) return "TEXT";      // MARK:   #define _C_CHARPTR  '*'
    else if ( first == _C_ATOM ) return "";     // MARK:   #define _C_ATOM     '%'
    else if ( first == _C_ARY_B ) return "";    // MARK:   #define _C_ARY_B    '['
    else if ( first == _C_ARY_E ) return "";    // MARK:   #define _C_ARY_E    ']'
    else if ( first == _C_UNION_B ) return "";  // MARK:   #define _C_UNION_B  '('
    else if ( first == _C_UNION_E ) return "";  // MARK:   #define _C_UNION_E  ')'
    else if ( first == _C_STRUCT_B ) return ""; // MARK:   #define _C_STRUCT_B '{'
    else if ( first == _C_STRUCT_E ) return ""; // MARK:   #define _C_STRUCT_E '}'
    else if ( first == _C_VECTOR ) return "";   // MARK:   #define _C_VECTOR   '!'
    else if ( first == _C_CONST ) return "";    // MARK:   #define _C_CONST    'r'
    return "";
}

/*!
 *  返回对象相应的数据库字段类型
 */
static char *_sjGetDatabaseObjType(const char *CType) {
    
    if      ( strstr(CType, "NSString") ) return "TEXT";
    else if ( strstr(CType, "NSMutableString") ) return "TEXT";
    else if ( strstr(CType, "NSArray") ) return "TEXT";
    else if ( strstr(CType, "NSMutableArray") ) return "TEXT";
    else if ( strstr(CType, "NSDictionary") ) return "";
    else if ( strstr(CType, "NSMutableDictionary") ) return "";
    else if ( strstr(CType, "NSSet") ) return "";
    else if ( strstr(CType, "NSMutableSet") ) return "";
    else if ( strstr(CType, "NSNumber") ) return "";
    else if ( strstr(CType, "NSValue") ) return "";
    else if ( strstr(CType, "NSURL") ) return "TEXT";
    
    return "";
}

typedef void(^SJIvarValueBlock)(id value);

//static id _sjGetIvarValue( id model, Ivar ivar) {
//    const char *CType = ivar_getTypeEncoding(ivar);
//    char first = CType[0];
//    if      ( first == _C_INT ||        //  Int
//              first == _C_UINT ||       //  Unsigned Int
//              first == _C_SHT ||        //  Short
//              first == _C_USHT ||       //  Unsigned Short
//              first == _C_LNG_LNG ||    //  Long Long
//              first == _C_ULNG_LNG ||   //  Unsigned Long
//              first == _C_BFLD ||       //  bool
//              first == _C_BOOL ||       //  BOOL
//              first == _C_ULNG_LNG )    //  Unsigned long long
//        return @(_sjIntValue(model, ivar));
//    else if ( first == _C_DBL ||        //  double
//              first == _C_FLT )         //  float
//        return @(_sjDoubleValue(model, ivar));
//    else if ( first == _C_CHARPTR )     //  char  *
//    {
//        char *charStr = _sjCharStrValue(model, ivar);
//        if ( strlen(charStr) > 0 )
//            return [NSString stringWithCString:charStr encoding:NSUTF8StringEncoding];
//        else return nil;
//    }
//    else return object_getIvar(model, ivar);
//}

/*!
 *  转换类型获取对应的Ivar的值
 */
//static NSInteger _sjIntValue(id obj, Ivar ivar) {
//    NSInteger (*value)(id, Ivar) = (NSInteger(*)(id, Ivar))object_getIvar;
//    return value(obj, ivar);
//}
//
//static double _sjDoubleValue(id obj, Ivar ivar) {
//    double(*value)(id, SEL) = (double(*)(id, SEL))objc_msgSend;
//    const char *selCStr = &ivar_getName(ivar)[1];
//    return value(obj, NSSelectorFromString([NSString stringWithUTF8String:selCStr]));
//}
//
//static char *_sjCharStrValue(id obj, Ivar ivar) {
//    char *(*value)(id, Ivar) = (char *(*)(id, Ivar))object_getIvar;
//    return value(obj, ivar);
//}
//
///*!
// *  模型转字典
// */
//static NSDictionary *_sjGetDict(id model) {
//    // 获取所有变量名
//    unsigned int ivarCount = 0;
//    struct objc_ivar **ivarList = class_copyIvarList([model class], &ivarCount);
//
//    // 获取所有变量值
//    NSMutableDictionary *valueDictM = [NSMutableDictionary new];
//    for ( int i = 0 ; i < ivarCount ; i ++ ) {
//        id ivarValue = _sjGetIvarValue(model, ivarList[i]);
//        if ( !ivarValue ) continue;
//        const char *ivarName = ivar_getName(ivarList[i]);
//        valueDictM[[NSString stringWithUTF8String:&ivarName[1]]] = ivarValue;
//    }
//    free(ivarList);
//    return valueDictM;
//}

/*!
 *  获取类中相关的私有变量
 */
inline static NSMutableSet<NSString *> *_sjGetIvarNames(Class cls) {
    NSMutableSet<NSString *> *ivarListSetM = [NSMutableSet new];
    unsigned int outCount = 0;
    Ivar *ivarList = class_copyIvarList(cls, &outCount);
    if (ivarList == NULL || 0 == outCount ) return nil;
    for (int i = 0; i < outCount; i ++) {
        const char *name = ivar_getName(ivarList[i]);
        NSString *nameStr = [NSString stringWithUTF8String:name];
        [ivarListSetM addObject:nameStr];
    }
    free(ivarList);
    return ivarListSetM;
}

#pragma mark -

- (id)filterValue:(id)target {
    if ( ![target isKindOfClass:[NSString class]] ) return target;
    if ( ![target containsString:@"'"] ) return target;
    return [target stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
}

#pragma mark -

/*!
 *  查询表中的所有字段
 *  select name from sqlite_master;
 */
- (NSMutableArray<NSString *> *)sjQueryTabAllFieldsWithClass:(Class)cls {
    NSString *sql = [NSString stringWithFormat:@"PRAGMA  table_info('%s');", [self sjGetTabName:cls]];
    NSMutableArray<NSString *> *dbFields = [NSMutableArray new];
    [[self _sjQueryWithSQLStr:sql] enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [dbFields addObject:obj[@"name"]];
    }];
    if ( 0 == dbFields.count ) return NULL;
    return dbFields;
}

#pragma mark -

- (BOOL)createTabWithClass:(Class)cls {
    if ( NULL == cls ) return NO;
    __block BOOL result = YES;
    [[self sjGetRelevanceClasses:cls] enumerateObjectsUsingBlock:^(Class  _Nonnull relevanceCls, BOOL * _Nonnull stop) {
        if ( [self _sjCreateOrAlterTabWithClass:relevanceCls] ) return;
        
        result = NO;
        *stop = YES;
    }];
    return result;
}

#pragma mark - insert or update
- (BOOL)insertOrUpdateDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models {
    __block BOOL result = YES;
    /*!
     *  归类整理
     */
    NSDictionary<NSString *, NSArray<id> *> *modelsDict = [self _sjPutInOrderModels:models];
    
    /*!
     *  自动创建表
     */
    [modelsDict.allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        result = [self _sjAutoCreateOrAlterRelevanceTabWithClass:NSClassFromString(obj)];
        if ( result ) return;
        
        result = NO;
        *stop = YES;
    }];
    
    if ( !result ) return result;
    
    /*!
     *  批量插入或更新
     */
    [modelsDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull tabName, NSArray<id> * _Nonnull modelsArr, BOOL * _Nonnull stop) {
        result = [self _sjInsertOrUpdateDataWithModels:modelsArr enableTransaction:YES];
        if ( result ) return;
        
        result = NO;
        *stop = YES;
    }];
    
    return result;
}

- (BOOL)update:(id<SJDBMapUseProtocol>)model property:(NSArray<NSString *> *)fields {
    id<SJDBMapUseProtocol> m = [self queryDataWithClass:[self _sjTargetClass:model] primaryValue:[[self sjGetPrimaryOrAutoPrimaryValue:model] integerValue]];
    if ( nil == m ) { return NO;}
    return [self _sjUpdate:model property:fields];
}

- (BOOL)update:(id<SJDBMapUseProtocol>)model insertedOrUpdatedValues:(NSDictionary<NSString *, id> *)insertedOrUpdatedValues {
    id<SJDBMapUseProtocol> m = [self queryDataWithClass:[self _sjTargetClass:model] primaryValue:[[self sjGetPrimaryOrAutoPrimaryValue:model] integerValue]];
    if ( nil == m ) { return NO;}
    
    return [self _sjUpdate:model insertedOrUpdatedValues:insertedOrUpdatedValues];
}

- (BOOL)updateTheDeletedValuesInTheModel:(id<SJDBMapUseProtocol>)model {
    id<SJDBMapUseProtocol> m = [self queryDataWithClass:[self _sjTargetClass:model] primaryValue:[[self sjGetPrimaryOrAutoPrimaryValue:model] integerValue]];
    if ( nil == m ) { return NO;}
    
    return [self _sjInsertOrUpdateDataWithModel:model uM:[self sjGetUnderstandingWithClass:[self _sjTargetClass:model]]];
}

#pragma mark - delete
- (BOOL)deleteDataWithClass:(Class)cls primaryValue:(NSInteger)primaryValue {
    SJDBMapUnderstandingModel *uM = [self sjGetUnderstandingWithClass:cls];
    NSAssert(uM.primaryKey || uM.autoincrementPrimaryKey, @"[%@] 该类没有设置主键", cls);
    NSString *sql = [self sjGetDeleteSQL:cls uM:uM deletePrimary:primaryValue];
    __block BOOL result = YES;
    [self _sjExeSQL:sql.UTF8String completeBlock:^(BOOL r) {
        if ( !r ) {
            NSLog(@"[%@] 删除失败.", sql);
            result = NO;
        }
    }];
    return result;
}

- (BOOL)deleteDataWithClass:(Class)cls primaryValues:(NSArray<NSNumber *> *)primaryValues {
    __block BOOL r = YES;
    NSString *sql = [self sjGetBatchDeleteSQL:cls primaryValues:primaryValues];
    [self _sjExeSQL:sql.UTF8String completeBlock:^(BOOL result) {
        if ( !result ) {
            NSLog(@"[%@] 删除失败.", sql);
            r = NO;
        }
    }];
    return r;
}

- (BOOL)deleteDataWithModels:(NSArray<id<SJDBMapUseProtocol>> *)models {
    __block BOOL r = YES;
    [[self _sjPutInOrderModels:models] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull clsName, NSArray<id<SJDBMapUseProtocol>> * _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *sql = [self sjGetBatchDeleteSQL:NSClassFromString(clsName) primaryValues:[self _sjGetPrimaryValues:obj]];
        [self _sjExeSQL:sql.UTF8String completeBlock:^(BOOL result) {
            if ( !result ) {
                NSLog(@"[%@] 删除失败.", sql);
                r = NO;
            }
        }];
    }];
    return r;
}

#pragma mark - query
- (BOOL)deleteDataWithClass:(Class)cls {
    if ( 0 == [self _sjQueryTabAllFields_Set_WithClass:cls] ) return YES;
    NSString *deleteSQL = [NSString stringWithFormat:@"DELETE FROM %s;", [self sjGetTabName:cls]];
    __block BOOL result = NO;
    [self _sjExeSQL:deleteSQL.UTF8String completeBlock:^(BOOL r) {
        result = r;
    }];
    return result;
}

/*!
 *  查询数据
 *
 *  返回转换成型的模型数据
 */
- (NSArray<id<SJDBMapUseProtocol>> *)queryAllDataWithClass:(Class)cls; {
    /*!
     *  获取存储数据
     */
    NSArray<NSDictionary *> *RawStorageData = [self _sjQueryRawStorageData:cls];
    if ( !RawStorageData ) return nil;
    SJDBMapQueryCache *cache = [SJDBMapQueryCache new];
    NSMutableArray<id> *allDataModel = [NSMutableArray new];
    NSArray<SJDBMapCorrespondingKeyModel *>*cKr = [self sjGetCorrespondingKeys:cls];
    NSArray<SJDBMapArrayCorrespondingKeysModel *> *aKr = [self sjGetArrayCorrespondingKeys:cls];
    [RawStorageData enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
        id model = [cls new];
        [self _sjConversionModelWithOwnerModel:model dict:dict cKr:cKr aKr:aKr memeryCache:cache];
        [allDataModel addObject:model];
    }];
    if ( 0 == allDataModel.count ) return nil;
    return allDataModel;
}

- (id<SJDBMapUseProtocol>)sjQueryDataWithClass:(Class)cls primaryValue:(NSInteger)primaryValue {
    NSDictionary *dict = [self _sjQueryRawStorageData:cls primaryValue:primaryValue];
    if ( !dict ) return nil;
    NSArray<SJDBMapCorrespondingKeyModel *>*cKr = [self sjGetCorrespondingKeys:cls];
    NSArray<SJDBMapArrayCorrespondingKeysModel *> *aKr = [self sjGetArrayCorrespondingKeys:cls];
    id model = [cls new];
    [self _sjConversionModelWithOwnerModel:model dict:dict cKr:cKr aKr:aKr memeryCache:[SJDBMapQueryCache new]];
    return model;
}

- (NSArray<id<SJDBMapUseProtocol>> *)queryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict {
    SJDBMapUnderstandingModel *uM = [self sjGetUnderstandingWithClass:cls];
    if ( !uM.primaryKey && !uM.autoincrementPrimaryKey ) return nil;
    NSAssert(uM.primaryKey || uM.autoincrementPrimaryKey, @"[%@] 该类没有设置主键", cls);
    
    const char *tabName = [self sjGetTabName:cls];
    
    NSMutableString *fieldsSqlM = [NSMutableString new];
    [fieldsSqlM appendFormat:@"select * from %s where ", tabName];
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [fieldsSqlM appendFormat:@"\"%@\" = '%@' and ", key, [self filterValue:obj]];
    }];
    [fieldsSqlM deleteCharactersInRange:NSMakeRange(fieldsSqlM.length - 5, 5)];
    [fieldsSqlM appendString:@";"];
    
    NSMutableArray<NSMutableDictionary *> *incompleteData = [NSMutableArray new];
    [[self _sjQueryWithSQLStr:fieldsSqlM] enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [incompleteData addObject:obj.mutableCopy];
    }];
    
    return [self _sjConversionMolding:cls rawStorageData:incompleteData memeryCache:[SJDBMapQueryCache new]];
}

- (NSArray<id<SJDBMapUseProtocol>> *)queryDataWithClass:(Class)cls range:(NSRange)range {
    SJDBMapUnderstandingModel *uM = [self sjGetUnderstandingWithClass:cls];
    if ( !uM.primaryKey && !uM.autoincrementPrimaryKey ) return nil;
    NSAssert(uM.primaryKey || uM.autoincrementPrimaryKey, @"[%@] 该类没有设置主键", cls);
    
    const char *tabName = [self sjGetTabName:cls];
    
    NSMutableString *fieldsSqlM = [NSMutableString new];
    [fieldsSqlM appendFormat:@"SELECT * FROM %s LIMIT %zd, %zd;", tabName, range.location, range.length];
    NSMutableArray<NSMutableDictionary *> *incompleteData = [NSMutableArray new];
    [[self _sjQueryWithSQLStr:fieldsSqlM] enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [incompleteData addObject:obj.mutableCopy];
    }];
    return [self _sjConversionMolding:cls rawStorageData:incompleteData memeryCache:[SJDBMapQueryCache new]];
}

- (NSArray<id<SJDBMapUseProtocol>> * _Nullable)fuzzyQueryDataWithClass:(Class)cls queryDict:(NSDictionary *)dict match:(SJDatabaseMapFuzzyMatch)match {
    if ( nil == cls || 0 == dict.allKeys ) return nil;
    return [self _sjFuzzyQueryConversionMolding:cls match:match dict:dict];
}
@end

/*!
 //    if      ( 0 == strcmp(type, @encode(short))) return "INTEGER";
 //    else if ( 0 == strcmp(type, @encode(unsigned short))) return "INTEGER";
 //    else if ( 0 == strcmp(type, @encode(int))) return "INTEGER";
 //    else if ( 0 == strcmp(type, @encode(unsigned int))) return "INTEGER";
 //    else if ( 0 == strcmp(type, @encode(long))) return "INTEGER";
 //    else if ( 0 == strcmp(type, @encode(unsigned long))) return "INTEGER";
 //    else if ( 0 == strcmp(type, @encode(long long))) return "INTEGER";
 //    else if ( 0 == strcmp(type, @encode(unsigned long long))) return "INTEGER";
 //    else if ( 0 == strcmp(type, @encode(NSInteger))) return "INTEGER";
 //    else if ( 0 == strcmp(type, @encode(float))) return "REAL";
 //    else if ( 0 == strcmp(type, @encode(double))) return "REAL";
 //    else if ( 0 == strcmp(type, @encode(char))) return "TEXT";
 //    else if ( 0 == strcmp(type, @encode(char *))) return "TEXT";
 //    else if ( 0 == strcmp(type, @encode(BOOL))) return "INTEGER";
 //    else if ( 0 == strcmp(type, @encode(bool))) return "INTEGER";
 //    else if ( 0 == strcmp(type, @encode(NSString))) return "TEXT";
 //    else if ( 0 == strcmp(type, @encode(NSMutableString))) return "TEXT";
 //    else if ( 0 == strcmp(type, @encode(NSArray))) return "TEXT";
 //    else if ( 0 == strcmp(type, @encode(NSMutableArray))) return "TEXT";
 */
