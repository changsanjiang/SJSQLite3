//
//  SJDatabaseFunctions.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2018/4/25.
//  Copyright © 2018年 SanJiang. All rights reserved.
//

#import "SJDatabaseFunctions.h"
#import <objc/message.h>

#define DEBUG_CONDITION (1)

NS_ASSUME_NONNULL_BEGIN


static void mark(char *sql, void(^)(void)); // ''

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
    char *error = NULL;
    bool r = (SQLITE_OK == sqlite3_exec(database, sql, NULL, NULL, &error));
    if ( error != NULL ) { printf("\nError ==> \n SQL  : %s\n Error: %s\n", sql, error); sqlite3_free(error);}
    return r;
}
extern NSArray<id> *__nullable sj_sql_query(sqlite3 *database, const char *sql, Class __nullable cls) {
    sqlite3_stmt *pstmt;
    bool result = (SQLITE_OK == sqlite3_prepare_v2(database, sql, -1, &pstmt, NULL));
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
    char *sql = malloc(sizeof(char) * 1024); sql[0] = '\0';

    const char *table_name = sj_table_name(carrier.cls);
    strcat(sql, "CREATE TABLE IF NOT EXISTS ");
    strcat(sql, table_name);
    strcat(sql, " (");
  
    NSArray<NSString *> *ivarList = sj_ivar_list(carrier.cls);
    
    __block BOOL primaryAdded = NO;
    const char *primayKeyOrAutoKey = carrier.isUsingPrimaryKey ? carrier.primaryKey.UTF8String : carrier.autoincrementPrimaryKey.UTF8String;
    [ivarList enumerateObjectsUsingBlock:^(NSString * _Nonnull ivar, NSUInteger idx, BOOL * _Nonnull stop) {
        // 主键 or 自增主键
        if ( !primaryAdded ) {
            if ( strcmp(&ivar.UTF8String[1], primayKeyOrAutoKey) == 0 ) {
                if ( carrier.isUsingPrimaryKey ) {
                    mark(sql, ^{ strcat(sql, carrier.primaryKey.UTF8String);});
                    strcat(sql, "INTEGER PRIMARY KEY,");
                }
                else {
                    mark(sql, ^{ strcat(sql, carrier.autoincrementPrimaryKey.UTF8String);});
                    strcat(sql, "INTEGER PRIMARY KEY AUTOINCREMENT,");
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
                mark(sql, ^{ strcat(sql, correspondingKey.UTF8String);});
                strcat(sql, "INTEGER");
                strcat(sql, ",");
                return;
            }
            printf("\nPrompt: 表: %s 字段: %s, 暂不支持存储.\n", sj_table_name(carrier.cls), ivar.UTF8String);
            return ;
        }
        
        // 其他键
        mark(sql, ^{ strcat(sql, &ivar.UTF8String[1]);});
        strcat(sql, sql_type);
        strcat(sql, ",");
    }];
    
    sql[strlen(sql) - 1] = '\0'; // 移除 最后一个逗号
    strcat(sql, ");"); // 结束

    bool result = sj_sql_exe(database, sql);

    if ( sql ) free(sql);
    
#if DEBUG_CONDITION
    if ( result ) {
        printf("\n创建成功: %s \nSQL: %s\n", table_name, sql);
    }
    else {
        printf("\n创建失败: %s \nSQL: %s\n", table_name, sql);
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

#pragma mark value
bool sj_value_insert_or_update(sqlite3 *database, id<SJDBMapUseProtocol> model, NSArray<__kindof SJDatabaseMapTableCarrier *> * __nullable container, SJDatabaseMapCache *__nullable cache) {
    if ( !cache ) cache = [SJDatabaseMapCache new];
    if ( [cache containsObject:model] ) return true;
    [cache addObject:model];
    
    __block SJDatabaseMapTableCarrier *carrier = nil;
    if ( !container ) {
        carrier = [[SJDatabaseMapTableCarrier alloc] initWithClass:[model class]];
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
    
    bool result = false;
    
    char *sql = malloc(500); sql[0] = '\0';
    strcat(sql, "INSERT OR REPLACE INTO");
    mark(sql, ^{ strcat(sql, table_name);});
    strcat(sql, " (");

    char *sql_values = malloc(500); sql_values[0] = '\0';
    strcat(sql_values, "VALUES(");
    
    NSArray<NSString *> *table_fields_list = sj_table_fields(database, table_name);
    __block BOOL _primaryKeyAdded = NO; // 主键是否已添加到 sql_values 中
    __block const char *_ivar = nil; // corresponding 对应的 ivar
    
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
            
            sj_value_insert_or_update(database, value, container, cache); // 插入或更新
            if ( !carrier_cor.isUsingPrimaryKey ) {
                long long autoId = [[value valueForKey:carrier_cor.autoincrementPrimaryKey] integerValue];
                if ( autoId == 0 ) { // 如果是自增主键, 防止重新插入, 在这里将其自增主键赋值
                    autoId = sj_value_last_id(database, [value class], carrier_cor);
                    [value setValue:@(autoId) forKey:carrier_cor.autoincrementPrimaryKey];
                }
            }
            
            long long _primarty_key_value = [[value valueForKey:field] integerValue];
            mark(sql, ^{ strcat(sql, field.UTF8String);}); // 'fields'
            mark(sql_values, ^{ strcat(sql_values, [NSString stringWithFormat:@"%lld", _primarty_key_value].UTF8String);}); // 'value'
            strcat(sql, ",");
            strcat(sql_values, ",");
        }
        
        if ( ![model respondsToSelector:NSSelectorFromString(field)] ) return;
        
        value = [(id)model valueForKey:field];
        if ( [value isKindOfClass:[NSArray class]] ) { // 处理 数组相应键
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
                sj_value_insert_or_update(database, obj, container, cache); // 插入或更新数据库
                if ( !carrier_arr.isUsingPrimaryKey ) {
                    long long autoId = [[obj valueForKey:carrier_arr.autoincrementPrimaryKey] integerValue];
                    if ( autoId == 0 ) { // 如果是自增主键, 防止重新插入, 在这里将其自增主键赋值
                        autoId = sj_value_last_id(database, _arr_e_cls, carrier_arr);
                        [obj setValue:@(autoId) forKey:carrier_arr.autoincrementPrimaryKey];
                    }
                }
                [corkey_primary_key_idsM addObject:[obj valueForKey:carrier_arr.primaryKeyOrAutoincrementPrimaryKey]];
            }];
            
            mark(sql, ^{ strcat(sql, field.UTF8String);}); // 'fields'
            
            NSData *data = [NSJSONSerialization dataWithJSONObject:@{NSStringFromClass(_arr_e_cls) : corkey_primary_key_idsM} options:0 error:nil];
            mark(sql_values, ^{ strcat(sql_values, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding].UTF8String);}); // 'value'
        }
        else if ( !_primaryKeyAdded && strcmp(field.UTF8String, carrier.primaryKeyOrAutoincrementPrimaryKey.UTF8String) == 0 ) {
            if ( !carrier.isUsingPrimaryKey ) {
                if ( [value integerValue] == 0 ) value = nil; // 置为nil, 使其自增
            }
            mark(sql, ^{ strcat(sql, field.UTF8String);});
            strcat(sql_values, [NSString stringWithFormat:@"%@", value].UTF8String);
            _primaryKeyAdded = YES;
        }
        else {  // 处理 普通键
            value = sj_value_filter(value); // 过滤一下
            mark(sql, ^{ strcat(sql, field.UTF8String);});
            mark(sql_values, ^{ strcat(sql_values, [NSString stringWithFormat:@"%@", value].UTF8String);});
        }
        
        strcat(sql, ",");
        strcat(sql_values, ",");
    }];
    
    
    sql[strlen(sql) - 1] = '\0';
    sql_values[strlen(sql_values) - 1] = '\0';
    
    strcat(sql, ") ");
    strcat(sql_values, ");");
    strcat(sql, sql_values);

    sj_sql_exe(database, sql);
    
    printf("\n --- %s \n ", sql);
    
    free(sql_values);
    free(sql);
    return result;
}

long long sj_value_last_id(sqlite3 *database, Class<SJDBMapUseProtocol> cls, SJDatabaseMapTableCarrier *__nullable carrier) {
    if ( !carrier ) carrier = [[SJDatabaseMapTableCarrier alloc] initWithClass:cls];
    long long last_id = -1;
    const char *table_name = sj_table_name(cls);
    char *sql = malloc(100); sql[0] = '\0';
    strcat(sql, "SELECT ");
    strcat(sql, carrier.primaryKeyOrAutoincrementPrimaryKey.UTF8String);
    strcat(sql, " FROM ");
    strcat(sql, table_name);
    strcat(sql, " ORDER BY ");
    strcat(sql, carrier.primaryKeyOrAutoincrementPrimaryKey.UTF8String);
    strcat(sql, " desc limit 1;");
    NSDictionary *result = sj_sql_query(database, sql, nil).firstObject;
    free(sql);
    if ( !result || 0 == result.count ) return last_id;
    last_id = [result[carrier.primaryKeyOrAutoincrementPrimaryKey] longLongValue];
    return last_id;
}

extern id sj_value_filter(id value) {
    if ( ![value isKindOfClass:[NSString class]] ) return value;
    return [(NSString *)value stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
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

static void mark(char *sql, void(^block)(void)) {
    strcat(sql, " '");
    block();
    strcat(sql, "' ");
}

#pragma mark -

@implementation SJDatabaseMapTableCarrier {
    NSMutableDictionary <NSString *, NSString *> * __nullable _correspondingKeysMapping; // `ivar` -> `corresponding`
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
            [arrayCorrespondingKeys enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class<SJDBMapUseProtocol>  _Nonnull cls, BOOL * _Nonnull stop) {
                NSAssert(cls != self.cls, ([NSString stringWithFormat:@"Error proprty: %@, 此property的class与主类一致, 无法继续操作", key]));
                SJDatabaseMapTableCorrespondingCarrier *carrier = [[SJDatabaseMapTableCorrespondingCarrier alloc] initWithClass:cls fields:key];
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
        NSString *fields = [ivar substringFromIndex:1];
        SJDatabaseMapTableCorrespondingCarrier *carrier = [[SJDatabaseMapTableCorrespondingCarrier alloc] initWithClass:ivar_cls fields:fields];
        [carrier parseCorrespondingKeysAddToContainer:container];
        [correspondingKeysM addObject:carrier];
        if ( !_correspondingKeysMapping ) _correspondingKeysMapping = [NSMutableDictionary new];
        _correspondingKeysMapping[ivar] = carrier.primaryKeyOrAutoincrementPrimaryKey;
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
        if ( strcmp(&ivar[1], obj.fields.UTF8String) != 0 ) return;
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
    __block const char *ivar_tmp = NULL;
    [_correspondingKeysMapping enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull corr, BOOL * _Nonnull stop) {
        if ( strcmp(corr.UTF8String, corresponding) != 0 ) return;
        ivar_tmp = key.UTF8String;
        *stop = YES;
    }];
    return ivar_tmp;
}
@end

@implementation SJDatabaseMapTableCorrespondingCarrier
- (instancetype)initWithClass:(Class<SJDBMapUseProtocol>)cls fields:(nonnull NSString *)fields {
    self = [super initWithClass:cls];
    if ( !self ) return nil;
    _fields = fields;
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
    __block BOOL contains = NO;
    NSString *className = NSStringFromClass([anObject class]);
    [self.modelCacheM enumerateObjectsUsingBlock:^(SJDatabaseMapCacheElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ( ![obj.className isEqualToString:className] ) return ;
        *stop = YES;
        contains = [obj.memeryM containsObject:anObject];
    }];
    return contains;
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
