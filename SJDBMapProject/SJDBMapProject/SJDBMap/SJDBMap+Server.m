//
//  SJDBMap+Server.m
//  SJProject
//
//  Created by BlueDancer on 2017/6/3.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SJDBMap+Server.h"
#import "SJDBMapHeader.h"

#define _SJLog

@implementation SJDBMap (Server)

/*!
 *  创建或更新一个表
 */
- (BOOL)sjCreateOrAlterTabWithClass:(Class)cls {
    /*!
     *  如果表不存在创建表
     */
    NSArray<NSString *> *fields = [self sjQueryTabAllFieldsWithClass:cls];
    if ( !fields ) {[self _sjCreateTab:cls]; return YES;}
    
    /*!
     *  如果表存在, 查看是否有更新字段
     */
    NSArray<NSString *> *ivarNames = _sjGetIvarNames(cls);
    NSMutableArray<NSString *> *addM = [NSMutableArray new];
    NSArray<SJDBMapCorrespondingKeyModel *> *cMs = [self sjGetCorrespondingKeys:cls];
    NSArray<SJDBMapArrayCorrespondingKeysModel *> *aMs = [self sjGetArrayCorrespondingKeys:cls];
    [ivarNames enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *field = [obj substringFromIndex:1];
        __block BOOL addBol = YES;
        [cMs enumerateObjectsUsingBlock:^(SJDBMapCorrespondingKeyModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ( [field isEqualToString:obj.ownerFields] ) {
                addBol = NO;
                *stop = YES;
            }
        }];
        [aMs enumerateObjectsUsingBlock:^(SJDBMapArrayCorrespondingKeysModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ( [field isEqualToString:obj.ownerFields]) {
                addBol = NO;
                *stop = YES;
            }
        }];
        if ( addBol ) if ( ![fields containsObject:field] ) [addM addObject:field];
    }];
    
    /*!
     *  如果有. 数据库新增字段
     */
    if ( addM.count > 0 ) {return [self _sjAlterFields:cls fields:addM];}
    
    return NO;
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
- (NSArray<NSString *> *)sjQueryTabAllFieldsWithClass:(Class)cls {
    NSString *sql = [NSString stringWithFormat:@"PRAGMA  table_info('%s');", class_getName(cls)];
    FMResultSet *set = [self.database executeQuery:sql];
    NSMutableArray<NSString *> *dbFields = [NSMutableArray new];
    while ( [set next] ) {
        [dbFields addObject:set.resultDictionary[@"name"]];
    }
    if ( !dbFields.count ) return NULL;
    return dbFields;
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
    const char *tabName = class_getName(cls);
    
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
        // 如果是相应键
        
        _sjmystrcat(sql, ",");
    }
    
    size_t length = strlen(sql);
    char lastChar = sql[length - 1];
    if ( lastChar == ',' ) sql[length - 1] = '\0';
    
    _sjmystrcat(sql, ");");
    
#ifdef _SJLog
    NSLog(@"%s", sql);
#endif
    
    if ( ![self.database executeUpdate:[NSString stringWithCString:sql encoding:NSUTF8StringEncoding]] ) {NSLog(@"[%@] 创建数据库失败", cls); return NO;}
    
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
    [fields enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *sql = [NSString stringWithFormat:@"ALTER TABLE '%s' ADD '%@' %s;", class_getName(cls), obj, _sjGetDatabaseIvarType(cls, [NSString stringWithFormat:@"_%@", obj].UTF8String)];
        if ( ![self.database executeUpdate:sql] ) { NSLog(@"[%@] 添加字段[%@]失败", cls, obj);};
#ifdef _SJLog
        NSLog(@"%@", sql);
#endif
    }];
    return YES;
}


/*!
 *  拼接字符串
 */
char *_sjmystrcat(char *dst, const char *src) {
    char *p = dst;
    while( *p != '\0' ) p++;
    while( *src != '\0' ) *p++ = *src++;
    *p = '\0';
    return p;
}

/*!
 *  返回变量相应的数据库字段类型
 */
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
    else if ( strstr(CType, "NSURL") ) return "";
    
    return "";
}

typedef void(^SJIvarValueBlock)(id value);

static id _sjGetIvarValue( id model, Ivar ivar) {
    const char *CType = ivar_getTypeEncoding(ivar);
    char first = CType[0];
    if      ( first == _C_INT ||        //  Int
              first == _C_UINT ||       //  Unsigned Int
              first == _C_SHT ||        //  Short
              first == _C_USHT ||       //  Unsigned Short
              first == _C_LNG_LNG ||    //  Long Long
              first == _C_ULNG_LNG ||   //  Unsigned Long
              first == _C_BFLD ||       //  bool
              first == _C_BOOL ||       //  BOOL
              first == _C_ULNG_LNG )    //  Unsigned long long
        return @(_sjIntValue(model, ivar));
    else if ( first == _C_DBL ||        //  double
              first == _C_FLT )         //  float
        return @(_sjDoubleValue(model, ivar));
    else if ( first == _C_CHARPTR )     //  char  *
    {
        char *charStr = _sjCharStrValue(model, ivar);
        if ( strlen(charStr) > 0 )
            return [NSString stringWithCString:charStr encoding:NSUTF8StringEncoding];
        else return nil;
    }
    else return object_getIvar(model, ivar);
}

/*!
 *  转换类型获取对应的Ivar的值
 */
static NSInteger _sjIntValue(id obj, Ivar ivar) {
    NSInteger (*value)(id, Ivar) = (NSInteger(*)(id, Ivar))object_getIvar;
    return value(obj, ivar);
}

static double _sjDoubleValue(id obj, Ivar ivar) {
    double(*value)(id, SEL) = (double(*)(id, SEL))objc_msgSend;
    const char *selCStr = &ivar_getName(ivar)[1];
    return value(obj, NSSelectorFromString([NSString stringWithUTF8String:selCStr]));
}

static char *_sjCharStrValue(id obj, Ivar ivar) {
    char *(*value)(id, Ivar) = (char *(*)(id, Ivar))object_getIvar;
    return value(obj, ivar);
}

/*!
 *  模型转字典
 */
NSDictionary *_sjGetDict(id model) {
    // 获取所有变量名
    unsigned int ivarCount = 0;
    struct objc_ivar **ivarList = class_copyIvarList([model class], &ivarCount);
    
    // 获取所有变量值
    NSMutableDictionary *valueDictM = [NSMutableDictionary new];
    for ( int i = 0 ; i < ivarCount ; i ++ ) {
        id ivarValue = _sjGetIvarValue(model, ivarList[i]);
        if ( !ivarValue ) continue;
        const char *ivarName = ivar_getName(ivarList[i]);
        valueDictM[[NSString stringWithUTF8String:&ivarName[1]]] = ivarValue;
    }
    free(ivarList);
    return valueDictM;
}

/*!
 *  获取类中相关的私有变量
 */
static NSArray<NSString *> *_sjGetIvarNames(Class cls) {
    NSMutableArray *invarListArrM = [NSMutableArray array];
    unsigned int outCount = 0;
    Ivar *ivarList = class_copyIvarList(cls, &outCount);
    if (ivarList == NULL || 0 == outCount ) return nil;
    for (int i = 0; i < outCount; i ++) {
        const char *name = ivar_getName(ivarList[i]);
        NSString *nameStr = [NSString stringWithUTF8String:name];
        [invarListArrM addObject:nameStr];
    }
    free(ivarList);
    return invarListArrM.copy;
}
@end
