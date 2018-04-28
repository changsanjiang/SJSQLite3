//
//  SJDatabaseFunctions.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2018/4/25.
//  Copyright © 2018年 SanJiang. All rights reserved.
//

#import "SJDatabaseFunctions.h"
#import <objc/message.h>

#define DEBUG_CONDITION (0)

NS_ASSUME_NONNULL_BEGIN


#pragma mark -

#pragma mark database
bool sj_database_open(const char *dbPath, sqlite3 **database) {
    bool result = (SQLITE_OK == sqlite3_open(dbPath, database));
#if DEBUG_CONDITION
    if ( result ) {
        printf("\n数据库打开成功! %s\n", dbPath);
    }
    else {
        printf("\n数据库打开失败! %s\n", dbPath);
    }
#endif
    return result;
}
bool sj_database_close(sqlite3 **database) {
    if ( !database ) return true;
    bool result = (SQLITE_OK == sqlite3_close(*database));
    if ( result ) *database = NULL;
#if DEBUG_CONDITION
    if ( result ) {
        printf("\n数据库关闭成功!\n");
    }
    else {
        printf("\n数据库关闭失败!\n");
    }
#endif
    return result;
}

#pragma mark transaction
void sj_transaction(sqlite3 *database, void(^sync_task)(void)) {
    sj_transaction_begin(database);
    if ( sync_task ) sync_task();
    sj_transaction_commit(database);
}
void sj_transaction_begin(sqlite3 *database) {
    sqlite3_exec(database, "begin", 0, 0, 0);
    printf("\n开启事物!\n");
}
void sj_transaction_commit(sqlite3 *database) {
    sqlite3_exec(database, "commit", 0, 0, 0);
    printf("\n提交事物!\n");
}

#pragma mark sql
static NSArray <id> *__nullable static_sj_sql_data(sqlite3_stmt *stmt, Class __nullable cls);

bool sj_sql_exe(sqlite3 *database, const char *sql) {
    char sql_str[strlen(sql) + 1];
    strcpy(sql_str, sql);
    char *error = NULL;
    bool r = (SQLITE_OK == sqlite3_exec(database, sql_str, NULL, NULL, &error));
    if ( error != NULL ) { printf("\nError ==> \n SQL  : %s\n Error: %s\n", sql_str, error); sqlite3_free(error);}
    printf("\n:: %s\n", sql_str);
    return r;
}
extern NSArray<id> *__nullable sj_sql_query(sqlite3 *database, const char *sql, Class __nullable cls) {
    char sql_str[strlen(sql) + 1];
    strcpy(sql_str, sql);
    sqlite3_stmt *pstmt = NULL;
    bool result = (SQLITE_OK == sqlite3_prepare_v2(database, sql_str, -1, &pstmt, NULL));
    NSArray <NSDictionary *> *dataArr = nil;
    if (result) dataArr = static_sj_sql_data(pstmt, cls);
    sqlite3_finalize(pstmt);
    return dataArr;
}

#pragma mark table
const char *sj_table_name(Class cls) {
    return class_getName(cls);
}
bool sj_table_create(sqlite3 *database, SJDatabaseMapTableCarrier * carrier) {
    const char *table_name = sj_table_name(carrier.cls);
    NSMutableString *sql_strM = [NSMutableString string];
    [sql_strM appendFormat:@"CREATE TABLE IF NOT EXISTS %s (", table_name];
    
    NSArray<NSString *> *ivarList = sj_ivar_list(carrier.cls);
    __block BOOL primaryAdded = NO;
    NSString *primayKeyOrAutoKey = carrier.primaryKeyOrAutoincrementPrimaryKey;
    [ivarList enumerateObjectsUsingBlock:^(NSString * _Nonnull ivar, NSUInteger idx, BOOL * _Nonnull stop) {
        // 主键 or 自增主键
        if ( !primaryAdded ) {
            if ( strcmp(&ivar.UTF8String[1], primayKeyOrAutoKey.UTF8String) == 0 ) {
                if ( carrier.isUsingPrimaryKey ) {
                    [sql_strM appendFormat:@"'%@' INTEGER PRIMARY KEY,", carrier.primaryKey];
                }
                else {
                    [sql_strM appendFormat:@"'%@' INTEGER PRIMARY KEY AUTOINCREMENT,", carrier.autoincrementPrimaryKey];
                }
                primaryAdded = YES;
                return ;
            }
        }
        
        // 是否是相应键
        const char *sql_type = sj_fields_sql_type(carrier.cls, ivar.UTF8String);
        if ( sql_type == NULL ) {
            NSString *correspondingKey = nil;
            BOOL isCoorespondingKey = [carrier isCorrespondingKeyWithIvar:ivar.UTF8String key:&correspondingKey];
            if ( isCoorespondingKey ) {
                [sql_strM appendFormat:@"'%@' INTEGER,", correspondingKey];
                return;
            }
            printf("\nPrompt: 表: %s 字段: %s, 暂不支持存储.\n", sj_table_name(carrier.cls), ivar.UTF8String);
            return ;
        }
        
        // 其他键
        [sql_strM appendFormat:@"'%s' %s,", &ivar.UTF8String[1], sql_type];
    }];
    
    [sql_strM deleteCharactersInRange:NSMakeRange(sql_strM.length - 1, 1)]; // 移除 最后一个逗号
    [sql_strM appendString:@");"]; // 结束

    bool result = sj_sql_exe(database, sql_strM.UTF8String);
    
#if DEBUG_CONDITION
    if ( result ) {
        printf("\n创建成功: %s \nSQL: %s\n", table_name, sql_strM.UTF8String);
    }
    else {
        printf("\n创建失败: %s \nSQL: %s\n", table_name, sql_strM.UTF8String);
    }
#endif
    
    return result;
}
bool sj_table_update(sqlite3 *database, SJDatabaseMapTableCarrier * carrier) {
    const char *table_name = sj_table_name(carrier.cls);
    NSArray<NSString *> *obj_ivar_list = sj_ivar_list(carrier.cls);
    NSArray<NSString *> *table_field_list = sj_table_fields(database, table_name);
    
    NSMutableSet<NSString *> *obj_field_set = [NSMutableSet new];
    [obj_ivar_list enumerateObjectsUsingBlock:^(NSString * _Nonnull ivar, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj_field_set addObject:[NSString stringWithFormat:@"%s", &ivar.UTF8String[1]]]; // 去掉下划线
    }];
    NSSet<NSString *> *table_field_set = [NSSet setWithArray:table_field_list];
    [obj_field_set minusSet:table_field_set]; // 去掉相同键
    if ( obj_field_set.count == 0 ) return true;
    
    sj_transaction_begin(database);
    __block bool result = YES;
    [obj_field_set enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        char *ivar = malloc(obj.length + 2);
        ivar[0] = '\0';
        strcat(ivar, "_");
        strcat(ivar, obj.UTF8String);
        const char *sql_type = sj_fields_sql_type(carrier.cls, ivar);
        if ( sql_type == NULL ) {
            NSString *correspondingKey = nil;
            BOOL isCoorespondingKey = [carrier isCorrespondingKeyWithIvar:ivar key:&correspondingKey];
            if ( isCoorespondingKey ) {
                if ( [table_field_set containsObject:correspondingKey] ) return ;
                result = sj_table_add_field(database, table_name, correspondingKey.UTF8String, "INTEGER");
                if ( !result ) *stop = YES;
                return;
            }
            printf("\nPrompt: 类: %s 字段: %s, 暂不支持存储.\n", sj_table_name(carrier.cls), obj.UTF8String);
        }
        else {
            result = sj_table_add_field(database, table_name, obj.UTF8String, sql_type);
            if ( !result ) *stop = YES;
        }
        free(ivar);
    }];
    sj_transaction_commit(database);
    return result;
}
bool sj_table_exists(sqlite3 *database, const char *table_name) {
    char *prefix = "SELECT count(*) FROM sqlite_master WHERE type='table' and name=";
    char *sql = malloc(1 + strlen(prefix) + strlen(table_name) + 3); // [1 -> \0] [3 -> NULL;]
    if ( !sql ) return false;
    strcat(sql, prefix);
    strcat(sql, "'");
    strcat(sql, table_name);
    strcat(sql, "';");
    bool result = [[sj_sql_query(database, sql, nil) firstObject][@"count(*)"] boolValue];
    free(sql);
    return result;
}
NSArray<NSString *> *__nullable sj_table_fields(sqlite3 *database, const char *table_name) {
    const char *sql = [NSString stringWithFormat:@"PRAGMA table_info('%s');", table_name].UTF8String;
    NSMutableArray<NSString *> *fieldsM = [NSMutableArray new];
    [sj_sql_query(database, sql, nil) enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [fieldsM addObject:obj[@"name"]];
    }];
    if ( fieldsM.count == 0 ) return nil;
    return fieldsM.copy;
}
bool sj_table_checkout_field(sqlite3 *database, const char *table_name, const char *field, const char *type) {
    NSArray<NSString *> *fields_arr = sj_table_fields(database, table_name);
    __block bool exists = false;
    [fields_arr enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ( strcmp(obj.UTF8String, field) != 0 ) return ;
        *stop = exists = true;
    }];
    if ( exists ) return true;
    return sj_table_add_field(database, table_name, field, type);
}
bool sj_table_add_field(sqlite3 *database, const char *table_name, const char *field, const char *type) {
    const char *sql = [NSString stringWithFormat:@"ALTER TABLE '%s' ADD \"%s\" %s;", table_name, field, type].UTF8String;
    bool result = sj_sql_exe(database, sql);
#if DEBUG_CONDITION
    if ( result ) {
        printf("\n添加字段成功: 表: %s SQL: %s\n", table_name, sql);
    }
    else {
        printf("\n添加字段失败: 表: %s SQL: %s\n", table_name, sql);
    }
#endif
    return result;
}
bool sj_table_delete(sqlite3 *database, const char *table_name) {
    NSMutableString *sql = [NSMutableString stringWithFormat:@"DROP TABLE %s;", table_name];
    return sj_sql_exe(database, sql.UTF8String);
}

#pragma mark value

bool sj_value_insert_or_update(sqlite3 *database, id<SJDBMapUseProtocol> model, NSArray<__kindof SJDatabaseMapTableCarrier *> * __nullable container, SJDatabaseMapCache *__nullable cache) {
    if ( !cache ) cache = [SJDatabaseMapCache new];
    if ( [cache containsObject:model] ) return true;
    [cache addObject:model];
    
    __block SJDatabaseMapTableCarrier *carrier = nil;
    if ( !container ) {
        carrier = [[SJDatabaseMapTableCarrier alloc] initWithClass:[model class]]; // 给 carrier 赋值
        [carrier parseCorrespondingKeysAddToContainer:(NSMutableArray *)(container = [NSMutableArray array])];
    }
    else {
        if ( [container isKindOfClass:[NSMutableArray class]] ) container = container.copy;
        [container enumerateObjectsUsingBlock:^(__kindof SJDatabaseMapTableCarrier * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ( obj.cls != [model class] ) return;
            carrier = obj;
            *stop = YES;
        }];
    }
    
    if ( !carrier ) {
        printf("\n 警告: 载体为空! \n");
        return false;
    }
    
    const char *table_name = sj_table_name(carrier.cls);
    if ( carrier.cls != [model class] ) {
#if DEBUG_CONDITION
        printf("\nInsert_Or_Update 操作失败, 模型类型与载体不一致: model: %s<%p>  carrier: %s\n", NSStringFromClass([model class]).UTF8String, model, table_name);
#endif
        return false;
    }
    
    __block bool result = false;

    NSMutableString *sql_strM = [NSMutableString string];
    [sql_strM appendFormat:@"INSERT OR REPLACE INTO '%s' (", table_name];
    
    NSMutableString *sql_valuesM = [NSMutableString string];
    [sql_valuesM appendFormat:@"VALUES("];
    
    NSArray<NSString *> *table_fields_list = sj_table_fields(database, table_name);
    __block BOOL _primaryKeyAdded = NO; // 主键是否已添加到 sql_values 中
    __block const char *_ivar = NULL; // corresponding 对应的 ivar
    
    [table_fields_list enumerateObjectsUsingBlock:^(NSString * _Nonnull field, NSUInteger idx, BOOL * _Nonnull stop) {
        id value = nil;

        if ( (_ivar = [carrier isCorrespondingKeyWithCorresponding:field.UTF8String]) != NULL ) { // 处理 相应键
            value = [(id)model valueForKey:[NSString stringWithUTF8String:_ivar]];
            __block SJDatabaseMapTableCarrier *carrier_cor = nil;
            [container enumerateObjectsUsingBlock:^(__kindof SJDatabaseMapTableCarrier * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ( obj.cls != [value class] ) return ;
                *stop = YES;
                carrier_cor = obj;
            }];
            if ( !carrier_cor ) return;
            
            result = sj_value_insert_or_update(database, value, container, cache); // 插入或更新
            if ( !result ) {
                *stop = YES;
                return;
            }
            
            if ( !carrier_cor.isUsingPrimaryKey ) {
                long long autoId = [[value valueForKey:carrier_cor.autoincrementPrimaryKey] integerValue];
                if ( autoId == 0 ) { // 如果是自增主键, 防止重新插入, 在这里将其自增主键赋值
                    autoId = sj_value_last_id(database, [value class], carrier_cor);
                    [value setValue:@(autoId) forKey:carrier_cor.autoincrementPrimaryKey];
                }
            }
            
            long long _primarty_key_value = [[value valueForKey:field] integerValue];

            [sql_strM appendFormat:@"'%@',", field];
            [sql_valuesM appendFormat:@"'%lld',", _primarty_key_value];
        }
        
        if ( ![model respondsToSelector:NSSelectorFromString(field)] ) { return;} // 过滤无法响应的字段
        
        result = false;
        value = [(id)model valueForKey:field];
        // 处理 数组相应键
        if ( [value isKindOfClass:[NSArray class]] ) {
            if ( [value count] == 0 ) return;
            Class _arr_e_cls = [[value firstObject] class];
            if ( ![_arr_e_cls conformsToProtocol:@protocol(SJDBMapUseProtocol)] ) return;
            
            __block SJDatabaseMapTableCarrier *carrier_arr = nil; // 查询数组内元素的载体
            [container enumerateObjectsUsingBlock:^(__kindof SJDatabaseMapTableCarrier * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ( obj.cls != _arr_e_cls ) return ;
                *stop = YES;
                carrier_arr = obj;
            }];
            if ( !carrier_arr ) return;
            NSMutableArray<NSNumber *> *corkey_primary_key_idsM = [NSMutableArray new]; // 数组内元素的id
            [(NSArray *)value enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                result = sj_value_insert_or_update(database, obj, container, cache); // 插入或更新数据库
                if ( !result ) {
                    return;
                    *stop = YES;
                }
                
                if ( !carrier_arr.isUsingPrimaryKey ) {
                    long long autoId = [[obj valueForKey:carrier_arr.autoincrementPrimaryKey] integerValue];
                    if ( autoId == 0 ) { // 如果是自增主键, 防止重新插入, 在这里将其自增主键赋值
                        autoId = sj_value_last_id(database, _arr_e_cls, carrier_arr);
                        [obj setValue:@(autoId) forKey:carrier_arr.autoincrementPrimaryKey];
                    }
                }
                [corkey_primary_key_idsM addObject:[obj valueForKey:carrier_arr.primaryKeyOrAutoincrementPrimaryKey]];
            }];
            
            if ( !result ) {
                *stop = YES;
                return;
            }
            
            NSData *data = [NSJSONSerialization dataWithJSONObject:@{NSStringFromClass(_arr_e_cls) : corkey_primary_key_idsM} options:0 error:nil];
            [sql_strM appendFormat:@"'%@',", field];
            [sql_valuesM appendFormat:@"'%@',", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]]; // 'value'

        }
        else if ( !_primaryKeyAdded && strcmp(field.UTF8String, carrier.primaryKeyOrAutoincrementPrimaryKey.UTF8String) == 0 ) { // 处理主键
            if ( !carrier.isUsingPrimaryKey ) {
                if ( [value integerValue] == 0 ) value = nil; // 置为nil, 使其自增
            }
            [sql_strM appendFormat:@"'%@',", field];
            [sql_valuesM appendFormat:@"%@,", value]; // 'value'
            _primaryKeyAdded = YES;
        }
        else {  // 处理 普通键
            value = sj_value_filter(value); // 过滤一下
            [sql_strM appendFormat:@"'%@',", field];
            [sql_valuesM appendFormat:@"'%@',", value]; // 'value'
        }
        
        result = YES;
    }];
    
    if ( !result ) {
        return false;
    }
    
    [sql_strM deleteCharactersInRange:NSMakeRange(sql_strM.length - 1, 1)];
    [sql_valuesM deleteCharactersInRange:NSMakeRange(sql_valuesM.length - 1, 1)];
    [sql_strM appendFormat:@") %@);", sql_valuesM];
    
    sj_sql_exe(database, sql_strM.UTF8String);
    
    printf("\n --- %s \n ", sql_strM.UTF8String);
    return result;
}
long long sj_value_last_id(sqlite3 *database, Class<SJDBMapUseProtocol> cls, SJDatabaseMapTableCarrier *__nullable carrier) {
    if ( !carrier ) carrier = [[SJDatabaseMapTableCarrier alloc] initWithClass:cls];
    long long last_id = -1;
    const char *table_name = sj_table_name(cls);
    NSMutableString *sql_str = [NSMutableString string];
    [sql_str appendFormat:@"SELECT %@ FROM %s ORDER BY %@ desc limit 1;", carrier.primaryKeyOrAutoincrementPrimaryKey, table_name, carrier.primaryKeyOrAutoincrementPrimaryKey];
    NSDictionary *result = sj_sql_query(database, sql_str.UTF8String, nil).firstObject;
    if ( !result || 0 == result.count ) return last_id;
    last_id = [result[carrier.primaryKeyOrAutoincrementPrimaryKey] longLongValue];
    return last_id;
}
id sj_value_filter(id value) {
    if ( ![value isKindOfClass:[NSString class]] ) return value;
    return [(NSString *)value stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
}
bool sj_value_update(sqlite3 *database, id<SJDBMapUseProtocol> model, NSArray<NSString *> *properties, NSArray<__kindof SJDatabaseMapTableCarrier *> * __nullable container, SJDatabaseMapCache *__nullable cache) {
    if ( [cache containsObject:model] ) return true;
    if ( !cache ) cache = [SJDatabaseMapCache new];
    [cache addObject:model];
    __block SJDatabaseMapTableCarrier *carrier = nil;
    if ( !container ) {
        carrier = [[SJDatabaseMapTableCarrier alloc] initWithClass:[model class]]; // 给 carrier 赋值
        [carrier parseCorrespondingKeysAddToContainer:(NSMutableArray *)(container = [NSMutableArray array])];
    }
    else {
        if ( [container isKindOfClass:[NSMutableArray class]] ) container = container.copy;
        [container enumerateObjectsUsingBlock:^(__kindof SJDatabaseMapTableCarrier * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ( obj.cls != [model class] ) return;
            carrier = obj;
            *stop = YES;
        }];
    }
    if ( !carrier ) {
        printf("\n 警告: 载体为空! \n");
        return false;
    }
    
    if ( !sj_value_exists(database, model, carrier) ) {
        return sj_value_insert_or_update(database, model, container, cache);
    }
    
    const char *table_name = sj_table_name([model class]);
    __block bool result = true;
    __block bool hasCommonFields = false;
    __block NSMutableString *_common_sql = nil; // 用于更新普通键
    [properties enumerateObjectsUsingBlock:^(NSString * _Nonnull property, NSUInteger idx, BOOL * _Nonnull stop) {
        if ( ![model respondsToSelector:NSSelectorFromString(property)] ) return; // 不响应的字段无法处理
        id value = [(id)model valueForKey:property];
        if ( !value ) return;
        char _ivar[property.length + 2]; _ivar[0] = '\0';
        strcpy(_ivar, [NSString stringWithFormat:@"_%@", property].UTF8String);
        NSString *_tmp = nil;
        if ( [carrier isCorrespondingKeyWithIvar:_ivar key:&_tmp] ) { // 处理相应键
            bool r = sj_value_insert_or_update(database, value, container, cache);
            if ( !r ) {
                result = false;
                *stop = YES;
                return;
            }
        }
        else if ( [carrier isArrCorrespondingKeyWithIvar:_ivar] ) { // 处理数组相应键
            [(NSArray *)value enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                bool r = sj_value_insert_or_update(database, obj, container, cache);
                if ( !r ) {
                    result = false;
                    *stop = YES;
                    return;
                }
            }];
            if ( !result ) return;
        }
        else { // 处理普通键
            hasCommonFields = true;
            if ( !_common_sql ) {
                _common_sql = [NSMutableString new];
                [_common_sql appendFormat:@"UPDATE %s SET ", table_name];
            }
            [_common_sql appendFormat:@"'%@'='%@',", property, sj_value_filter(value)];
        }
    }];
    if ( !result ) return false;
    if ( _common_sql ) {
        [_common_sql deleteCharactersInRange:NSMakeRange(_common_sql.length - 1, 1)]; // 去除最后的逗号
        [_common_sql appendFormat:@" WHERE %@=%@;", carrier.primaryKeyOrAutoincrementPrimaryKey, [(id)model valueForKey:carrier.primaryKeyOrAutoincrementPrimaryKey]];
        result = sj_sql_exe(database, _common_sql.UTF8String);
        
#if DEBUG_CONDITION
        printf("\n%s \n", _common_sql.UTF8String);
#endif
    }
    return result;
}
extern bool sj_value_exists(sqlite3 *database, id<SJDBMapUseProtocol> model, SJDatabaseMapTableCarrier *__nullable carrier) {
    if ( !carrier ) {
        carrier = [[SJDatabaseMapTableCarrier alloc] initWithClass:[model class]];
    }
    const char *table_name = sj_table_name([model class]);
    const char *sql = [NSString stringWithFormat:@"SELECT *FROM %s WHERE %@ = %@;", table_name, carrier.primaryKeyOrAutoincrementPrimaryKey, [(id)model valueForKey:carrier.primaryKeyOrAutoincrementPrimaryKey]].UTF8String;
    return sj_sql_query(database, sql, nil).count != 0;
}
extern bool sj_value_delete(sqlite3 *database, const char *table_name, const char *fields, NSArray *values) {
    NSMutableString *sql = [NSMutableString stringWithFormat:@"DELETE FROM %s WHERE %s in (", table_name, fields];
    [values enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [sql appendFormat:@"%@,", sj_value_filter(obj)];
    }];
    [sql deleteCharactersInRange:NSMakeRange(sql.length - 1, 1)];
    [sql appendFormat:@");"];
    return sj_sql_exe(database, sql.UTF8String);
}
NSArray<id<SJDBMapUseProtocol>> *sj_value_query(sqlite3 *database, const char *sql_str, Class<SJDBMapUseProtocol> cls, NSArray<__kindof SJDatabaseMapTableCarrier *> * __nullable container, SJDatabaseMapCache *__nullable cache) {
    if ( strlen(sql_str) == 0 ) return nil;
    
    char sql[strlen(sql_str) + 1];
    strcpy(sql, sql_str);

    if ( !cache ) {
        cache = [SJDatabaseMapCache new];
    }
    
    __block SJDatabaseMapTableCarrier *carrier = nil; // 当前载体
    if ( !container ) {
        carrier = [[SJDatabaseMapTableCarrier alloc] initWithClass:cls];        // ...
        [carrier parseCorrespondingKeysAddToContainer:(NSMutableArray *)(container = [NSMutableArray array])];
    }
    else {
        if ( [container isKindOfClass:[NSMutableArray class]] ) container = container.copy;
        [container enumerateObjectsUsingBlock:^(__kindof SJDatabaseMapTableCarrier * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ( obj.cls != cls ) return;
            *stop = YES;
            carrier = obj;                                                      // ...
        }];
    }
    
    if ( !carrier ) {
        printf("\n 警告: 载体为空! \n");
        return false;
    }
    
    sqlite3_stmt *pstmt;
    bool result = (SQLITE_OK == sqlite3_prepare_v2(database, sql, -1, &pstmt, NULL));
    if ( !result ) return nil;
    
    NSMutableArray *resultM = [NSMutableArray new];
    while ( sqlite3_step(pstmt) == SQLITE_ROW ) {
        id model = [(Class)cls new];
        [resultM addObject:model];
        int column_count = sqlite3_column_count(pstmt);
        for ( int i = 0 ; i < column_count ; ++i ) {
            const char *fields = sqlite3_column_name(pstmt, i);
            NSString *oc_property = [NSString stringWithUTF8String:fields];
            int type = sqlite3_column_type(pstmt, i);
            switch ( type ) {
                case SQLITE_INTEGER: {
                    int value = sqlite3_column_int(pstmt, i);
                    // 如果是相应键
                    const char *instance_ivar = [carrier isCorrespondingKeyWithCorresponding:fields];
                    if ( instance_ivar ) {
                        __block SJDatabaseMapTableCorrespondingCarrier *carrier_cor = nil;
                        for ( int i = 0 ; i < carrier.correspondingKeys_arr.count ; ++ i ) {
                            SJDatabaseMapTableCorrespondingCarrier *obj = carrier.correspondingKeys_arr[i];
                            if ( strcmp(obj.property.UTF8String, &instance_ivar[1]) != 0 ) continue;
                            carrier_cor = obj;
                            break;
                        }
                        if ( !carrier_cor ) break;
                        if ( ![model respondsToSelector:NSSelectorFromString(carrier_cor.property)] ) break;
                        
                        id<SJDBMapUseProtocol> model_cor = [cache containsObjectWithClass:carrier_cor.cls primaryValue:value];
                        if ( !model_cor ) {
                            const char *table_name = sj_table_name(carrier_cor.cls);
                            const char *sql = [NSString stringWithFormat:@"SELECT *FROM %s WHERE %@=%d;", table_name, carrier_cor.primaryKeyOrAutoincrementPrimaryKey, value].UTF8String;
                            model_cor = sj_value_query(database, sql, carrier_cor.cls, container, cache).firstObject;
                            [cache addObject:model_cor];
                        }
                        [model setValue:model_cor forKey:carrier_cor.property];
                    }
                    else {
                        if ( ![model respondsToSelector:NSSelectorFromString(oc_property)] ) break;
                        [model setValue:@(value) forKey:oc_property];
                    }
                }
                    break;
                case SQLITE_TEXT: {
                    if ( ![model respondsToSelector:NSSelectorFromString(oc_property)] ) break;
                    const unsigned char *value = sqlite3_column_text(pstmt, i);
                    NSString *value_str = [NSString stringWithUTF8String:(const char *)value];
                    if ( [carrier isArrCorrespondingKeyWithIvar:[NSString stringWithFormat:@"_%s", fields].UTF8String] ) {
                        NSData *data = [value_str dataUsingEncoding:NSUTF8StringEncoding];
                        NSDictionary<NSString *, NSArray<NSNumber *> *> *arrPrimaryValuesDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                        // 其实这个字典就一个key
                        [arrPrimaryValuesDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull className, NSArray<NSNumber *> * _Nonnull primaryValues, BOOL * _Nonnull stop) {
                            Class cls = NSClassFromString(className);
                            __block SJDatabaseMapTableCorrespondingCarrier *carrier_arr = nil;
                            [container enumerateObjectsUsingBlock:^(__kindof SJDatabaseMapTableCarrier * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                if ( obj.cls != cls ) return ;
                                carrier_arr = obj;
                            }];
                            if ( !carrier_arr ) return ;
                            NSMutableArray<id<SJDBMapUseProtocol>> *modelsM = [NSMutableArray new];
                            [primaryValues enumerateObjectsUsingBlock:^(NSNumber * _Nonnull primaryValue, NSUInteger idx, BOOL * _Nonnull stop) {
                                id<SJDBMapUseProtocol> model_arr = [cache containsObjectWithClass:cls primaryValue:[primaryValue integerValue]];
                                if ( !model_arr ) {
                                    const char *table_name = sj_table_name(cls);
                                    const char *sql = [NSString stringWithFormat:@"SELECT *FROM %s WHERE %@=%ld;", table_name, carrier_arr.primaryKeyOrAutoincrementPrimaryKey, (long)[primaryValue integerValue]].UTF8String;
                                    model_arr = sj_value_query(database, sql, carrier_arr.cls, container, cache).firstObject;
                                    [cache addObject:model_arr];
                                }
                                [modelsM addObject:model_arr];
                            }];
                            [model setValue:modelsM forKey:oc_property];
                        }];
                    }
                    else {
                        [model setValue:value_str forKey:oc_property];
                    }
                }
                    break;
                case SQLITE_FORMAT: {
                    if ( ![model respondsToSelector:NSSelectorFromString(oc_property)] ) break;
                    double value = sqlite3_column_double(pstmt, i);
                    [model setValue:@(value) forKey:oc_property];
                }
                    break;
            }
        }
    }
    sqlite3_finalize(pstmt);
    return resultM;
}
#pragma mark - fileds type
static char *__nullable _sj_object_OC_type(const char *CType);

char *__nullable sj_fields_sql_type(Class cls, const char *ivar) {
    Ivar iv = class_getInstanceVariable(cls, ivar);
    const char *type = ivar_getTypeEncoding(iv);
    char first = type[0];
    if      ( first == _C_ID )
        return _sj_object_OC_type(type);                // MARK:   #define _C_ID       '@'
    else if ( first == _C_CLASS ) return NULL;     // MARK:   #define _C_CLASS    '#'
    else if ( first == _C_SEL ) return "TEXT";          // MARK:   #define _C_SEL      ':'
    else if ( first == _C_CHR ) return "TEXT";          // MARK:   #define _C_CHR      'c'
    else if ( first == _C_UCHR ) return "TEXT";         // MARK:   #define _C_UCHR     'C'
    else if ( first == _C_SHT ) return "INTEGER";       // MARK:   #define _C_SHT      's'
    else if ( first == _C_USHT ) return "INTEGER";      // MARK:   #define _C_USHT     'S'
    else if ( first == _C_INT ) return "INTEGER";       // MARK:   #define _C_INT      'i'
    else if ( first == _C_UINT ) return "INTEGER";      // MARK:   #define _C_UINT     'I'
    else if ( first == _C_LNG ) return NULL;      // MARK:   #define _C_LNG      'l'
    else if ( first == _C_ULNG ) return NULL;     // MARK:   #define _C_ULNG     'L'
    else if ( first == _C_LNG_LNG ) return "INTEGER";   // MARK:   #define _C_LNG_LNG  'q'
    else if ( first == _C_ULNG_LNG ) return "INTEGER";  // MARK:   #define _C_ULNG_LNG 'Q'
    else if ( first == _C_FLT ) return "REAL";          // MARK:   #define _C_FLT      'f'
    else if ( first == _C_DBL ) return "REAL";          // MARK:   #define _C_DBL      'd'
    else if ( first == _C_BFLD ) return NULL;     // MARK:   #define _C_BFLD     'b'
    else if ( first == _C_BOOL ) return "INTEGER";      // MARK:   #define _C_BOOL     'B'
    else if ( first == _C_VOID ) return NULL;     // MARK:   #define _C_VOID     'v'
    else if ( first == _C_UNDEF ) return NULL;    // MARK:   #define _C_UNDEF    '?'
    else if ( first == _C_PTR ) return NULL;      // MARK:   #define _C_PTR      '^'
    else if ( first == _C_CHARPTR ) return "TEXT";      // MARK:   #define _C_CHARPTR  '*'
    else if ( first == _C_ATOM ) return NULL;     // MARK:   #define _C_ATOM     '%'
    else if ( first == _C_ARY_B ) return NULL;    // MARK:   #define _C_ARY_B    '['
    else if ( first == _C_ARY_E ) return NULL;    // MARK:   #define _C_ARY_E    ']'
    else if ( first == _C_UNION_B ) return NULL;  // MARK:   #define _C_UNION_B  '('
    else if ( first == _C_UNION_E ) return NULL;  // MARK:   #define _C_UNION_E  ')'
    else if ( first == _C_STRUCT_B ) return NULL; // MARK:   #define _C_STRUCT_B '{'
    else if ( first == _C_STRUCT_E ) return NULL; // MARK:   #define _C_STRUCT_E '}'
    else if ( first == _C_VECTOR ) return NULL;   // MARK:   #define _C_VECTOR   '!'
    else if ( first == _C_CONST ) return NULL;    // MARK:   #define _C_CONST    'r'
    return NULL;
}

static char *_sj_object_OC_type(const char *CType) {
    
    if      ( strstr(CType, "NSString") ) return "TEXT";
    else if ( strstr(CType, "NSMutableString") ) return "TEXT";
    else if ( strstr(CType, "NSArray") ) return "TEXT";
    else if ( strstr(CType, "NSMutableArray") ) return "TEXT";
    else if ( strstr(CType, "NSDictionary") ) return NULL;
    else if ( strstr(CType, "NSMutableDictionary") ) return NULL;
    else if ( strstr(CType, "NSSet") ) return NULL;
    else if ( strstr(CType, "NSMutableSet") ) return NULL;
    else if ( strstr(CType, "NSNumber") ) return NULL;
    else if ( strstr(CType, "NSValue") ) return NULL;
    else if ( strstr(CType, "NSURL") ) return NULL;
    
    return NULL;
}

#pragma mark folder or file
NSString *__nullable sj_checkoutFolder(NSString *path) {
    NSError *error = nil;
    if ( ![[NSFileManager defaultManager] fileExistsAtPath:path] ) [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
    return error ? nil : path;
}

#pragma mark - static
static NSArray <id> *__nullable static_sj_sql_data(sqlite3_stmt *stmt, Class __nullable cls) {
    NSMutableArray *dataArrM = [[NSMutableArray alloc] init];
    while ( sqlite3_step(stmt) == SQLITE_ROW ) {
        id model = nil;
        if ( cls ) model = [cls new];
        else model = [NSMutableDictionary new];
        int columnCount = sqlite3_column_count(stmt);
        for ( int i = 0; i < columnCount ; ++ i ) {
            const char *c_key = sqlite3_column_name(stmt, i);
            NSString *oc_key = [NSString stringWithCString:c_key encoding:NSUTF8StringEncoding];
            int type = sqlite3_column_type(stmt, i);
            switch (type) {
                case SQLITE_INTEGER: {
                    int value = sqlite3_column_int(stmt, i);
                    [model setValue:@(value) forKey:oc_key];
                }
                    break;
                case SQLITE_TEXT: {
                    const  char *value = (const  char *)sqlite3_column_text(stmt, i);
                    [model setValue:[NSString stringWithUTF8String:value] forKey:oc_key];
                }
                    break;
                case SQLITE_FLOAT: {
                    double value = sqlite3_column_double(stmt, i);
                    [model setValue:@(value) forKey:oc_key];
                }
                    break;
                default:
                    break;
            }
        }
        [dataArrM addObject:model];
    }
    if ( dataArrM.count == 0 ) return nil;
    return dataArrM.copy;
}

#pragma mark runtime
NSArray<NSString *> *sj_ivar_list(Class cls) {
    NSMutableArray *ivarListArrM = [NSMutableArray array];
    unsigned int outCount = 0;
    Ivar *ivarList = class_copyIvarList(cls, &outCount);
    if ( !ivarList ) return nil;
    if ( 0 == outCount ) return nil;
    for ( int i = 0 ; i < outCount ; ++i ) {
        const char *name = ivar_getName(ivarList[i]);
        NSString *nameStr = [NSString stringWithUTF8String:name];
        [ivarListArrM addObject:nameStr];
    }
    free(ivarList);
    return ivarListArrM.copy;
}
Class sj_ivar_class(Class cls, const char *ivar) {
    Ivar iv = class_getInstanceVariable(cls, ivar);
    const char *encoding = ivar_getTypeEncoding(iv);
    char first = encoding[0];
    if ( first != _C_ID ) return NULL;
// @"type"
    size_t encodinglen = strlen(encoding);
    char cls_str[encodinglen];

    int index = 0;
    for ( int i = 0 ; i < encodinglen ; ++ i ) {
        const char c = encoding[i];
        if ( c != '@' && c != '"' ) {
            cls_str[index++] = c;
        }
    }
    cls_str[index] = '\0';
    return objc_getClass(cls_str);
}

#pragma mark -

@implementation SJDatabaseMapTableCarrier {
    NSMutableDictionary <NSString *, NSString *> * __nullable _correspondingKeysMapping; // `ivar` -> `corresponding`
    char _tmpCorrsponding[100];
}

- (instancetype)initWithClass:(Class<SJDBMapUseProtocol>)cls {
    self = [super init];
    if ( !self ) return nil;
    NSAssert(cls, @"Error: cls 不能为空!");
    _cls = cls;
    if ( [cls respondsToSelector:@selector(primaryKey)] ) {
        _primaryKey = [cls primaryKey];
        _isUsingPrimaryKey = YES;
    }
    
    if ( [cls respondsToSelector:@selector(autoincrementPrimaryKey)] ) {
        NSAssert(!_isUsingPrimaryKey, @"Error: 主键和自增主键只能实现一个!");
        _autoincrementPrimaryKey = [cls autoincrementPrimaryKey];
        _isUsingPrimaryKey = NO;
    }
    return self;
}

- (void)parseCorrespondingKeysAddToContainer:(NSMutableArray<__kindof SJDatabaseMapTableCarrier *> *)container {
    NSAssert(container, @"Error: 容器不能为空!");
    
     [container addObject:self];
    
    Class<SJDBMapUseProtocol> cls = self.cls;
    if ( [cls respondsToSelector:@selector(arrayCorrespondingKeys)] ) {
        NSDictionary<NSString *,Class<SJDBMapUseProtocol>> *arrayCorrespondingKeys = [cls arrayCorrespondingKeys];
        if ( 0 != arrayCorrespondingKeys.count ) {
            NSMutableArray<SJDatabaseMapTableCorrespondingCarrier *> *arrayCorrespondingKeys_arrM = [NSMutableArray arrayWithCapacity:arrayCorrespondingKeys.count];
            [arrayCorrespondingKeys enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull property, Class<SJDBMapUseProtocol>  _Nonnull cls, BOOL * _Nonnull stop) {
                NSAssert(cls != self.cls, ([NSString stringWithFormat:@"Error proprty: %@, 此property的class与主类一致, 无法继续操作", property]));
                SJDatabaseMapTableCorrespondingCarrier *carrier = [[SJDatabaseMapTableCorrespondingCarrier alloc] initWithClass:cls property:property];
                [carrier parseCorrespondingKeysAddToContainer:container];
                [arrayCorrespondingKeys_arrM addObject:carrier];
            }];
            _arrayCorrespondingKeys_arr = arrayCorrespondingKeys_arrM.copy;
        }
    }
    
    NSArray<NSString *> *ivarList = sj_ivar_list(cls);
    NSAssert(ivarList.count, @"Error class: 没有属性可以存储! 至少需要一个能够存储的属性...");
    
    NSMutableArray<SJDatabaseMapTableCorrespondingCarrier *> *correspondingKeysM = [NSMutableArray arrayWithCapacity:ivarList.count];
    [ivarList enumerateObjectsUsingBlock:^(NSString * _Nonnull ivar, NSUInteger idx, BOOL * _Nonnull stop) {
        Class ivar_cls = sj_ivar_class(cls, ivar.UTF8String);
        if ( !ivar_cls ) return;
        NSAssert(ivar_cls != self.cls, ([NSString stringWithFormat:@"Error proprty: %@, 此property的class与主类一致, 无法继续操作", ivar]));
        if ( ![ivar_cls conformsToProtocol:@protocol(SJDBMapUseProtocol)] ) return;
        NSString *property = [ivar substringFromIndex:1];
        SJDatabaseMapTableCorrespondingCarrier *carrier = [[SJDatabaseMapTableCorrespondingCarrier alloc] initWithClass:ivar_cls property:property];
        [carrier parseCorrespondingKeysAddToContainer:container];
        [correspondingKeysM addObject:carrier];
        if ( !self->_correspondingKeysMapping ) self->_correspondingKeysMapping = [NSMutableDictionary new];
        self->_correspondingKeysMapping[ivar] = carrier.primaryKeyOrAutoincrementPrimaryKey;
    }];
    if ( correspondingKeysM.count != 0 ) _correspondingKeys_arr = correspondingKeysM.copy;
}

- (NSString *)primaryKeyOrAutoincrementPrimaryKey {
    if ( _isUsingPrimaryKey ) return _primaryKey;
    else return _autoincrementPrimaryKey;
}

- (BOOL)isArrCorrespondingKeyWithIvar:(const char *)ivar {
    __block BOOL isArrCorKey = NO;
    [self.arrayCorrespondingKeys_arr enumerateObjectsUsingBlock:^(SJDatabaseMapTableCorrespondingCarrier * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ( strcmp(&ivar[1], obj.property.UTF8String) != 0 ) return;
        isArrCorKey = YES;
        *stop = YES;
    }];
    return isArrCorKey;
}

- (BOOL)isCorrespondingKeyWithIvar:(const char *)ivar key:(NSString * __autoreleasing *)key {
    NSString *filedsStr = [NSString stringWithUTF8String:ivar];
    NSString *tmpKey = _correspondingKeysMapping[filedsStr];
    if ( tmpKey.length != 0 ) {
        if ( key ) *key = tmpKey;
        return YES;
    }
    return NO;
}

- (const char *)isCorrespondingKeyWithCorresponding:(const char *)corresponding {
    _tmpCorrsponding[0] = '\0';
    [_correspondingKeysMapping enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull corr, BOOL * _Nonnull stop) {
        if ( strcmp(corr.UTF8String, corresponding) != 0 ) return;
        strcpy(self->_tmpCorrsponding, key.UTF8String);
        *stop = YES;
    }];
    return _tmpCorrsponding[0] != '\0' ? _tmpCorrsponding : NULL;
}
@end

@implementation SJDatabaseMapTableCorrespondingCarrier
- (instancetype)initWithClass:(Class<SJDBMapUseProtocol>)cls property:(nonnull NSString *)property {
    self = [super initWithClass:cls];
    if ( !self ) return nil;
    _property = property;
    return self;
}
@end

#pragma mark -
@interface SJDatabaseMapCacheElement : NSObject
@property (nonatomic, strong) NSString *className;
@property (nonatomic, strong, readonly) NSMutableArray<id<SJDBMapUseProtocol>> *memeryM;
@end

@implementation SJDatabaseMapCacheElement
@synthesize memeryM = _memeryM;
- (NSMutableArray<id<SJDBMapUseProtocol>> *)memeryM {
    if ( _memeryM ) return _memeryM;
    _memeryM = [NSMutableArray array];
    return _memeryM;
}
@end

@interface SJDatabaseMapCache ()
@property (nonatomic, strong, readonly) NSMutableArray<SJDatabaseMapCacheElement *> *modelCacheM;
@end

@implementation SJDatabaseMapCache
@synthesize modelCacheM = _modelCacheM;

- (void)addObject:(id<SJDBMapUseProtocol>)object {
    if ( !object ) return;
    NSString *classeName = NSStringFromClass([object class]);
    __block BOOL added = NO;
    [self.modelCacheM enumerateObjectsUsingBlock:^(SJDatabaseMapCacheElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ( ![classeName isEqualToString:obj.className] ) return;
        [obj.memeryM addObject:object];
        added = YES;
        *stop = YES;
    }];
    
    if ( added ) return;
    
    SJDatabaseMapCacheElement *element = [SJDatabaseMapCacheElement new];
    element.className = classeName;
    [element.memeryM addObject:object];
    [self.modelCacheM addObject:element];
}

- (BOOL)containsObject:(id<SJDBMapUseProtocol>)anObject {
    if ( !anObject ) return NO;
    __block BOOL contains = NO;
    NSString *className = NSStringFromClass([anObject class]);
    [self.modelCacheM enumerateObjectsUsingBlock:^(SJDatabaseMapCacheElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ( ![obj.className isEqualToString:className] ) return ;
        *stop = YES;
        contains = [obj.memeryM containsObject:anObject];
    }];
    return contains;
}

- (nullable id<SJDBMapUseProtocol>)containsObjectWithClass:(Class<SJDBMapUseProtocol>)cls primaryValue:(NSInteger)primaryValue {
    if ( !cls ) return nil;
    __block id<SJDBMapUseProtocol> model = nil;
    NSString *className = NSStringFromClass(cls);
    SJDatabaseMapTableCarrier *carrier = [[SJDatabaseMapTableCarrier alloc] initWithClass:cls];
    NSString *primaryKey = carrier.primaryKeyOrAutoincrementPrimaryKey;
    [self.modelCacheM enumerateObjectsUsingBlock:^(SJDatabaseMapCacheElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ( ![obj.className isEqualToString:className] ) return ;
        *stop = YES;
        [obj.memeryM enumerateObjectsUsingBlock:^(id<SJDBMapUseProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSInteger value = [[(id)obj valueForKey:primaryKey] integerValue];
            if ( value != primaryValue ) return ;
            *stop = YES;
            model = obj;
        }];
    }];
    return model;
}

- (NSMutableArray<SJDatabaseMapCacheElement *> *)modelCacheM {
    if ( _modelCacheM ) return _modelCacheM;
    _modelCacheM = [NSMutableArray new];
    return _modelCacheM;
}
- (void)dealloc {
    NSLog(@"%d - %s", (int)__LINE__, __func__);
}
@end
NS_ASSUME_NONNULL_END
