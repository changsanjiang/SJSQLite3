//
//  SJDatabaseMap+Server.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/6/6.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SJDatabaseMap+Server.h"
#import "SJDBMap.h"

#define _SJLog

@implementation SJDatabaseMap (Server)

/*!
 *  执行SQL语句
 */
- (void)sjExeSQL:(const char *)sql completeBlock:(void(^)(BOOL r))block {
    BOOL r = (SQLITE_OK == sqlite3_exec(self.sqDB, sql, NULL, NULL, NULL));
    if ( block ) block(r);
}

/*!
 *  创建或更新一张表
 */
- (BOOL)sjCreateOrAlterTabWithClass:(Class)cls {
    
    /*!
     *  如果表不存在创建表
     */
    NSMutableSet<NSString *> *fieldsSet = [self _sjQueryTabAllFields_Set_WithClass:cls];
    if ( !fieldsSet ) {[self _sjCreateTab:cls]; return YES;}
    
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
        
        if ( NULL == fields) fields = objF.UTF8String, dbType = _sjGetDatabaseIvarType(cls, [NSString stringWithFormat:@"_%@", objF].UTF8String);
        
        NSString *sql = [NSString stringWithFormat:@"ALTER TABLE '%s' ADD '%s' %s;", tabName, fields, dbType];
        
        [self sjExeSQL:sql.UTF8String completeBlock:^(BOOL result) {
            if ( !result ) NSLog(@"[%@] 添加字段[%@]失败", cls, objF), exeSQLResultBol = NO;
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
- (void)sjAutoCreateOrAlterRelevanceTabWithClass:(Class)cls {
    [[self sjGetRelevanceClasses:cls] enumerateObjectsUsingBlock:^(Class  _Nonnull relevanceCls, BOOL * _Nonnull stop) {
        [self sjCreateOrAlterTabWithClass:relevanceCls];
    }];
}

/*!
 *  查询表中的所有字段
 */
- (NSMutableArray<NSString *> *)sjQueryTabAllFieldsWithClass:(Class)cls {
    NSString *sql = [NSString stringWithFormat:@"PRAGMA  table_info('%s');", [self sjGetTabName:cls]];
    NSMutableArray<NSString *> *dbFields = [NSMutableArray new];
    [[self sjQueryWithSQLStr:sql] enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [dbFields addObject:obj[@"name"]];
    }];
    if ( !dbFields.count ) return NULL;
    return dbFields;
}

- (NSMutableSet<NSString *> *)_sjQueryTabAllFields_Set_WithClass:(Class)cls {
    NSString *sql = [NSString stringWithFormat:@"PRAGMA  table_info('%s');", [self sjGetTabName:cls]];
    NSMutableSet<NSString *> *dbFields = [NSMutableSet new];
    [[self sjQueryWithSQLStr:sql] enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [dbFields addObject:obj[@"name"]];
    }];
    if ( !dbFields.count ) return NULL;
    return dbFields;
}

/*!
 *  整理模型数据
 */
- (NSDictionary<NSString *, NSArray<id<SJDBMapUseProtocol>> *> *)sjPutInOrderModels:(NSArray<id> *)models {
    NSMutableDictionary<NSString *, NSMutableArray<id> *> *modelsDictM = [NSMutableDictionary new];
    [models enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *tabName = NSStringFromClass([obj class]);
        if ( !modelsDictM[tabName] ) modelsDictM[tabName] = [NSMutableArray new];
        [modelsDictM[tabName] addObject:obj];
    }];
    return modelsDictM;
}

/*!
 *  返回转换成型的模型数据
 */
- (NSArray<id<SJDBMapUseProtocol>> *)sjQueryConversionMolding:(Class)cls {
    /*!
     *  获取存储数据
     */
    NSArray<NSDictionary *> *RawStorageData = [self sjQueryRawStorageData:cls];
    if ( !RawStorageData ) return nil;
    NSMutableArray<id> *allDataModel = [NSMutableArray new];
    NSArray<SJDBMapCorrespondingKeyModel *>*cKr = [self sjGetCorrespondingKeys:cls];
    NSArray<SJDBMapArrayCorrespondingKeysModel *> *aKr = [self sjGetArrayCorrespondingKeys:cls];
    [RawStorageData enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
        id model = [cls new];
        [self _sjConversionModelWithOwnerModel:model dict:dict cKr:cKr aKr:aKr];
        [allDataModel addObject:model];
    }];
    if ( 0 == allDataModel.count ) return nil;
    return allDataModel;
}

- (id<SJDBMapUseProtocol>)sjQueryConversionMolding:(Class)cls primaryValue:(NSInteger)primaryValue {
    NSDictionary *dict = [self sjQueryRawStorageData:cls primaryValue:primaryValue];
    if ( !dict ) return nil;
    NSArray<SJDBMapCorrespondingKeyModel *>*cKr = [self sjGetCorrespondingKeys:cls];
    NSArray<SJDBMapArrayCorrespondingKeysModel *> *aKr = [self sjGetArrayCorrespondingKeys:cls];
    id model = [cls new];
    [self _sjConversionModelWithOwnerModel:model dict:dict cKr:cKr aKr:aKr];
    return model;
}
 
- (NSArray<id<SJDBMapUseProtocol>> *)sjQueryConversionMolding:(Class)cls dict:(NSDictionary *)dict {
    SJDBMapUnderstandingModel *uM = [self sjGetUnderstandingWithClass:cls];
    if ( !uM.primaryKey && !uM.autoincrementPrimaryKey ) return nil;
    NSAssert(uM.primaryKey || uM.autoincrementPrimaryKey, @"[%@] 该类没有设置主键", cls);
    
    const char *tabName = [self sjGetTabName:cls];
    
    NSMutableString *fieldsSqlM = [NSMutableString new];
    [fieldsSqlM appendFormat:@"select * from %s where ", tabName];
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ( [obj isKindOfClass:[NSString class]] && [(NSString *)obj containsString:@"'"] )
            [fieldsSqlM appendFormat:@"%@ = \"%@\"", key, obj];
        else
            [fieldsSqlM appendFormat:@"%@ = '%@'", key, obj];
        [fieldsSqlM appendString:@" and "];
    }];
    [fieldsSqlM deleteCharactersInRange:NSMakeRange(fieldsSqlM.length - 5, 5)];
    [fieldsSqlM appendString:@";"];
    
    NSMutableArray<NSMutableDictionary *> *incompleteData = [NSMutableArray new];
    [[self sjQueryWithSQLStr:fieldsSqlM] enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [incompleteData addObject:obj.mutableCopy];
    }];
    
    return [self _sjConversionMolding:cls rawStorageData:incompleteData];
}

/*!
 *  根据条件模糊查询
 */
- (NSArray<id<SJDBMapUseProtocol>> *)sjFuzzyQueryConversionMolding:(Class)cls match:(SJDatabaseMapFuzzyMatch)match dict:(NSDictionary *)dict {
    SJDBMapUnderstandingModel *uM = [self sjGetUnderstandingWithClass:cls];
    if ( !uM.primaryKey && !uM.autoincrementPrimaryKey ) return nil;
    NSAssert(uM.primaryKey || uM.autoincrementPrimaryKey, @"[%@] 该类没有设置主键", cls);
    
    const char *tabName = [self sjGetTabName:cls];
    
    NSMutableString *fieldsSqlM = [NSMutableString new];
    [fieldsSqlM appendFormat:@"select * from %s where ", tabName];
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        
        switch (match) {
                //      *  ...A...
            case SJDatabaseMapFuzzyMatchAll:
            {
                if ( [obj isKindOfClass:[NSString class]] && [(NSString *)obj containsString:@"'"] )
                    [fieldsSqlM appendFormat:@"%@ like \"%%%@%%\"", key, obj];
                else
                    [fieldsSqlM appendFormat:@"%@ like '%%%@%%'", key, obj];
            }
                break;
                //      *  ABC.....
            case SJDatabaseMapFuzzyMatchFront:
            {
                if ( [obj isKindOfClass:[NSString class]] && [(NSString *)obj containsString:@"'"] )
                    [fieldsSqlM appendFormat:@"%@ like \"%@%%\"", key, obj];
                else
                    [fieldsSqlM appendFormat:@"%@ like '%@%%'", key, obj];
            }
                break;
                //     *  ...DEF
            case SJDatabaseMapFuzzyMatchLater:
            {
                if ( [obj isKindOfClass:[NSString class]] && [(NSString *)obj containsString:@"'"] )
                    [fieldsSqlM appendFormat:@"%@ like \"%%%@\"", key, obj];
                else
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
    [[self sjQueryWithSQLStr:fieldsSqlM] enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [incompleteData addObject:obj.mutableCopy];
    }];
    
    return [self _sjConversionMolding:cls rawStorageData:incompleteData];
}


- (NSArray<id> *)_sjConversionMolding:(Class)cls rawStorageData:(NSArray<NSDictionary *> *)rawStorageData {
    NSMutableArray<id> *allDataModel = [NSMutableArray new];
    NSArray<SJDBMapCorrespondingKeyModel *>*cKr = [self sjGetCorrespondingKeys:cls];
    NSArray<SJDBMapArrayCorrespondingKeysModel *> *aKr = [self sjGetArrayCorrespondingKeys:cls];
    [rawStorageData enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
        id model = [cls new];
        [self _sjConversionModelWithOwnerModel:model dict:dict cKr:cKr aKr:aKr];
        [allDataModel addObject:model];
    }];
    if ( 0 == allDataModel.count ) return nil;
    return allDataModel;
}

/*!
 *  查询数据库原始存储数据
 */
- (NSArray<NSDictionary *> *)sjQueryRawStorageData:(Class)cls {
    const char *tabName = [self sjGetTabName:cls];
    NSString *sql = [NSString stringWithFormat:@"select *from %s;", tabName];
    
    NSMutableArray<NSMutableDictionary *> *incompleteData = [NSMutableArray new];
    [[self sjQueryWithSQLStr:sql] enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [incompleteData addObject:obj.mutableCopy];
    }];
    return incompleteData;
}

/*!
 *  查询数据库原始存储数据
 */
- (NSDictionary *)sjQueryRawStorageData:(Class)cls primaryValue:(NSInteger)primaryValue {
    SJDBMapUnderstandingModel *uM = [self sjGetUnderstandingWithClass:cls];
    NSAssert(uM.primaryKey || uM.autoincrementPrimaryKey, @"[%@] 该类没有设置主键", cls);
    const char *tabName = [self sjGetTabName:cls];
    NSString *fields = uM.primaryKey ? uM.primaryKey.ownerFields : uM.autoincrementPrimaryKey.ownerFields;
    NSString *sql = [NSString stringWithFormat:@"select * from %s where %@ = %zd;", tabName, fields, primaryValue];
    __block NSDictionary *incompleteData = nil;
    [[self sjQueryWithSQLStr:sql] enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        incompleteData = obj;
    }];
    return incompleteData;
}

- (void)_sjConversionModelWithOwnerModel:(id)model dict:(NSDictionary *)dict cKr:(NSArray<SJDBMapCorrespondingKeyModel *>*)cKr aKr:(NSArray<SJDBMapArrayCorrespondingKeysModel *> *)aKr {
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull fields, id  _Nonnull fieldsValue, BOOL * _Nonnull stop) {
        
        __block BOOL continueBool = NO;
        [cKr enumerateObjectsUsingBlock:^(SJDBMapCorrespondingKeyModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ( [fields isEqualToString:obj.correspondingFields] ) {
                NSInteger cPrimaryValue = [fieldsValue integerValue];
                id cmodel = [obj.correspondingCls new];
                NSArray<SJDBMapCorrespondingKeyModel *>*ccKr = [self sjGetCorrespondingKeys:obj.correspondingCls];
                NSArray<SJDBMapArrayCorrespondingKeysModel *> *caKr = [self sjGetArrayCorrespondingKeys:obj.correspondingCls];
                [self _sjConversionModelWithOwnerModel:cmodel dict:[self sjQueryRawStorageData:obj.correspondingCls primaryValue:cPrimaryValue] cKr:ccKr aKr:caKr];
                [model setValue:cmodel forKey:obj.ownerFields];
                continueBool = YES;
                *stop = YES;
            }
        }];
        
        if ( continueBool ) return;
        
        [aKr enumerateObjectsUsingBlock:^(SJDBMapArrayCorrespondingKeysModel * _Nonnull ACKM, NSUInteger idx, BOOL * _Nonnull stop) {
            if ( [fields isEqualToString:ACKM.ownerFields] ) {
                NSData *data = [fieldsValue dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary<NSString *, NSArray<NSNumber *> *> *aPrimaryValues = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                [aPrimaryValues enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<NSNumber *> * _Nonnull obj, BOOL * _Nonnull stop) {
                    NSMutableArray<id> *ar = [NSMutableArray new];
                    [obj enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        id amodel = [ACKM.correspondingCls new];
                        NSArray<SJDBMapCorrespondingKeyModel *>*ccKr = [self sjGetCorrespondingKeys:ACKM.correspondingCls];
                        NSArray<SJDBMapArrayCorrespondingKeysModel *> *caKr = [self sjGetArrayCorrespondingKeys:ACKM.correspondingCls];
                        [self _sjConversionModelWithOwnerModel:amodel dict:[self sjQueryRawStorageData:ACKM.correspondingCls primaryValue:[obj integerValue]] cKr:ccKr aKr:caKr];
                        [ar addObject:amodel];
                    }];
                    [model setValue:ar forKey:ACKM.ownerFields];
                }];
                continueBool = YES;
                *stop = YES;
            }
        }];
        
        if ( continueBool ) return;
        
        if ( [model respondsToSelector:NSSelectorFromString(fields)] ) {
            [model setValue:fieldsValue forKey:fields];
        }
    }];
}

/*!
 *  插入
 */
- (BOOL)sjInsertOrUpdateDataWithModel:(id<SJDBMapUseProtocol>)model {
    __block BOOL result = YES;
    [[self sjGetRelevanceObjs:model] enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        SJDBMapUnderstandingModel *uM = [self sjGetUnderstandingWithClass:[obj class]];
        NSString *prefixSQL  = [self sjGetInsertOrUpdatePrefixSQL:uM];
        NSString *subffixSQL = [self sjGetInsertOrUpdateSuffixSQL:obj];
        NSString *sql = [NSString stringWithFormat:@"%@ %@;", prefixSQL, subffixSQL];
        [self sjExeSQL:sql.UTF8String completeBlock:^(BOOL r) {
            if ( !r ) result = NO, NSLog(@"[%@] 插入或更新失败", model);
            SJDBMapAutoincrementPrimaryKeyModel *aPKM = [self sjGetAutoincrementPrimaryKey:[obj class]];
            if ( !aPKM ) return;
            id aPKV = [(id)obj valueForKey:aPKM.ownerFields];
            if ( [aPKV integerValue] ) return;
            aPKV = [self sjGetLastDataIDWithClass:[obj class] autoincrementPrimaryKeyModel:aPKM];
            /*!
             *  如果是自增主键, 在模型自增主键为0的情况下, 插入完数据后, 为这个模型的自增主键赋值. 防止重复插入.
             */
            if ( !aPKV ) return;
            [(id)obj setValue:aPKV forKey:aPKM.ownerFields];
        }];
    }];
    return result;
}

/*!
 *  获取主键值
 */
- (NSArray<NSNumber *> *)sjGetPrimaryValues:(NSArray<id<SJDBMapUseProtocol>> *)models {
    if ( !models.count ) return nil;
    NSString *primaryFields = [self sjGetPrimaryKey:[models[0] class]].ownerFields;
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
    
    unsigned int ivarCount = 0;
    
    __block struct objc_ivar **ivarList = class_copyIvarList(cls, &ivarCount);
    
    SJDBMapUnderstandingModel *model = [self sjGetUnderstandingWithClass:cls];
    
    NSAssert(model.primaryKey || model.autoincrementPrimaryKey, @"[%@] 只能有一个主键.", cls);
    
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
    
    for (int i = 0; i < ivarCount; i ++) {
        char *ivarName = (char *)ivar_getName(ivarList[i]);
        
        char *field = &ivarName[1];
        char *fieldType = _sjGetDatabaseIvarType(cls, ivarName);
        
        // 提取相应字段(如果有)
        __block SJDBMapCorrespondingKeyModel *correspondingKeyModel = nil;
        [model.correspondingKeys enumerateObjectsUsingBlock:^(SJDBMapCorrespondingKeyModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ( 0 == strcmp(field, obj.ownerFields.UTF8String) ) {correspondingKeyModel = obj; *stop = YES;};
        }];
        
        if ( correspondingKeyModel ) {
            field = (char *)(correspondingKeyModel.correspondingFields.UTF8String);
            fieldType = "INTEGER";
        }
        
        // 如果字段类型未知, 目前跳过该字段
        if ( 0 == strlen(fieldType) ) continue;
        
        _sjmystrcat(sql, " ");
        _sjmystrcat(sql, field);
        _sjmystrcat(sql, " ");
        _sjmystrcat(sql, fieldType);
        
        // 如果是自增主键
        if      ( NULL != model.autoincrementPrimaryKey &&
                 0 == strcmp(field, model.autoincrementPrimaryKey.ownerFields.UTF8String) )
            _sjmystrcat(sql, " PRIMARY KEY AUTOINCREMENT");
        // 如果是主键
        else if ( NULL != model.primaryKey &&
                 0 == strcmp(field, model.primaryKey.ownerFields.UTF8String) )
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
    
    __weak typeof(self) _self = self;
    [self sjExeSQL:sql completeBlock:^(BOOL result) {
        if ( !result ) NSLog(@"[%@] 创建表失败", cls);
        if ( !model.autoincrementPrimaryKey ) return;
        
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        /*!
         *  如果是自增键。由于 0 在OC 中为空。 遇到自增主键值为0时，不好判断出是插入还是更新。为了避免这种情况，让ID从1开始。
         */
        [self sjExeSQL:[NSString stringWithFormat:@"dbcc checkident('%s', reseed, 0)", tabName].UTF8String completeBlock:nil];
    }];
    
    
    free(sql);
    free(ivarList);
    
    sql = NULL;
    ivarList = NULL;
    
    return YES;
}

/*!
 *  向一个表中新增字段
 */
- (BOOL)_sjAlterFields:(Class)cls fields:(NSArray<NSString *> *)fields {
    if ( 0 == fields.count ) return YES;
    __block BOOL result = YES;
    [fields enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *sql = [NSString stringWithFormat:@"ALTER TABLE '%s' ADD '%@' %s;", [self sjGetTabName:cls], obj, _sjGetDatabaseIvarType(cls, [NSString stringWithFormat:@"_%@", obj].UTF8String)];
        [self sjExeSQL:sql.UTF8String completeBlock:^(BOOL r) {
            if ( !r ) NSLog(@"[%@] 添加字段[%@]失败", cls, obj), result = NO;
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
- (NSArray<NSDictionary *> *)sjQueryWithSQLStr:(NSString *)sqlStr {
    
    sqlite3_stmt *stmt;
    int result = sqlite3_prepare_v2(self.sqDB, sqlStr.UTF8String, -1, &stmt, NULL);
    
    NSArray <NSDictionary *> *dataArr = nil;
    
    if (SQLITE_OK == result) dataArr = [self sjGetTabDataWithStmt:stmt];
    
    sqlite3_finalize(stmt);
    
    return dataArr;
}

- (NSArray <NSDictionary *> *)sjGetTabDataWithStmt:(sqlite3_stmt *)stmt {
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
static NSMutableSet<NSString *> *_sjGetIvarNames(Class cls) {
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
