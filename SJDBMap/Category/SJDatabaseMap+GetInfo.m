//
//  SJDatabaseMap+GetInfo.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/6/6.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SJDatabaseMap+GetInfo.h"

#import <objc/message.h>

#import "SJDatabaseMap+Server.h"
#import "SJDBMapUnderstandingModel.h"
#import "SJDBMapPrimaryKeyModel.h"
#import "SJDBMapAutoincrementPrimaryKeyModel.h"
#import "SJDBMapCorrespondingKeyModel.h"
#import "SJDBMapArrayCorrespondingKeysModel.h"



@implementation SJDatabaseMap (GetInfo)

/*!
 *  获取与该类相关的类
 */
- (NSMutableSet<Class> *)sjGetRelevanceClasses:(Class)cls {
    NSMutableSet<Class> *set = [NSMutableSet new];
    [set addObject:cls];
    [self _sjCycleGetCorrespondingKeyWithClass:cls container:set];
    [self _sjCycleGetArrayCorrespondingKeyWithClass:cls container:set];
    return set;
}

- (void)_sjCycleGetCorrespondingKeyWithClass:(Class)cls container:(NSMutableSet<Class> *)set {
    [[self sjGetCorrespondingKeys:cls] enumerateObjectsUsingBlock:^(SJDBMapCorrespondingKeyModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        NSAssert(model.correspondingCls, @"[%@] 该类没有[%@]字段", model.ownerCls, model.ownerFields);
        [set addObject:model.correspondingCls];
        [self _sjCycleGetCorrespondingKeyWithClass:model.correspondingCls container:set];
        [self _sjCycleGetArrayCorrespondingKeyWithClass:model.correspondingCls container:set];
    }];
}

- (void)_sjCycleGetArrayCorrespondingKeyWithClass:(Class)cls container:(NSMutableSet<Class> *)set {
    [[self sjGetArrayCorrespondingKeys:cls] enumerateObjectsUsingBlock:^(SJDBMapArrayCorrespondingKeysModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        [set addObject:model.correspondingCls];
        [self _sjCycleGetCorrespondingKeyWithClass:model.correspondingCls container:set];
        [self _sjCycleGetArrayCorrespondingKeyWithClass:model.correspondingCls container:set];
    }];
}

/*!
 *  获取与该对象相关的对象
 */
- (NSMutableSet<id<SJDBMapUseProtocol>> *)sjGetRelevanceObjs:(id<SJDBMapUseProtocol>)rootObj {
    if ( !rootObj ) return nil;
    NSMutableSet<id<SJDBMapUseProtocol>> *set = [NSMutableSet new];
    [set addObject:rootObj];
    [self _sjCycleGetCorrespondingValueWithObj:rootObj container:set];
    [self _sjCycleGetArrayCorrespondingValueWithObj:rootObj container:set];
    return set;
}

- (void)_sjCycleGetCorrespondingValueWithObj:(id<SJDBMapUseProtocol>)obj container:(NSMutableSet<id<SJDBMapUseProtocol>> *)set {
    [[self sjGetCorrespondingKeys:[obj class]] enumerateObjectsUsingBlock:^(SJDBMapCorrespondingKeyModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        id value = [(id)obj valueForKey:model.ownerFields];
        if ( !value ) return;
        [set addObject:value];
        [self _sjCycleGetCorrespondingValueWithObj:value container:set];
        [self _sjCycleGetArrayCorrespondingValueWithObj:value container:set];
    }];
}

- (void)_sjCycleGetArrayCorrespondingValueWithObj:(id<SJDBMapUseProtocol>)obj container:(NSMutableSet<id<SJDBMapUseProtocol>> *)set {
    [[self sjGetArrayCorrespondingKeys:[obj class]] enumerateObjectsUsingBlock:^(SJDBMapArrayCorrespondingKeysModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<id> *values = [(id)obj valueForKey:model.ownerFields];
        if ( !values ) return;
        [values enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [set addObject:obj];
            [self _sjCycleGetCorrespondingValueWithObj:obj container:set];
            [self _sjCycleGetArrayCorrespondingValueWithObj:obj container:set];
        }];
    }];
}

/*!
 *  获取与该类所有相关的协议
 */
- (NSArray<SJDBMapUnderstandingModel *> *)sjGetRelevanceUnderstandingModels:(Class)cls {
    NSMutableArray<SJDBMapUnderstandingModel *> *arrM = [NSMutableArray new];
    [[self sjGetRelevanceClasses:cls] enumerateObjectsUsingBlock:^(Class  _Nonnull obj, BOOL * _Nonnull stop) {
        [arrM addObject:[self sjGetUnderstandingWithClass:obj]];
    }];
    return arrM;
}

/*!
 *  获取某个类的协议实现
 */
- (SJDBMapUnderstandingModel *)sjGetUnderstandingWithClass:(Class)cls {
    SJDBMapUnderstandingModel *model = [SJDBMapUnderstandingModel new];
    model.ownerCls = cls;
    model.primaryKey = [self sjGetPrimaryKey:cls];
    model.autoincrementPrimaryKey = [self sjGetAutoincrementPrimaryKey:cls];
    model.correspondingKeys = [self sjGetCorrespondingKeys:cls];
    model.arrayCorrespondingKeys = [self sjGetArrayCorrespondingKeys:cls];
    return model;
}

/*!
 *  生成插入或更新的前缀Sql语句
 *  example:
 *      INSERT OR REPLACE INTO 'SJPrice' ('price','priceID')
 */
- (NSString *)sjGetInsertOrUpdatePrefixSQL:(SJDBMapUnderstandingModel *)model {
    if ( !model.ownerCls ) { return NULL;}
    // 获取表名
    const char *tabName = [self sjGetTabName:model.ownerCls];
    // SQL语句
    char *sql = (char *)malloc(1024);
    *sql = '\0';
    _sjmystrcat(sql, "INSERT OR REPLACE INTO ");
    _sjmystrcat(sql, tabName);
    _sjmystrcat(sql, " (");
    
    NSArray<NSString *> *tabFields = [self sjQueryTabAllFieldsWithClass:model.ownerCls];
    
    [tabFields enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        _sjmystrcat(sql, "'");
        _sjmystrcat(sql, obj.UTF8String);
        _sjmystrcat(sql, "',");
    }];
    
    if ( sql[strlen(sql) - 1] == ',' ) sql[strlen(sql) - 1] = '\0';
    _sjmystrcat(sql, ")");
    NSString *sqlStr = [NSString stringWithFormat:@"%s", sql];
    free(sql);
    return sqlStr;
}

/*!
 *  生成插入或更新的后缀Sql语句
 *  example:
 *      VALUES('15','1');
 */
- (NSString *)sjGetInsertOrUpdateSuffixSQL:(id<SJDBMapUseProtocol>)model {
    if ( !model ) return nil;
    NSMutableString *sqlM = [NSMutableString new];
    [sqlM appendString:@"VALUES("];
    
    SJDBMapAutoincrementPrimaryKeyModel *autoincrementPrimaryKeyModel = [self sjGetAutoincrementPrimaryKey:[model class]];
    NSArray<SJDBMapCorrespondingKeyModel *>*cK = [self sjGetCorrespondingKeys:[model class]];
    NSArray<SJDBMapArrayCorrespondingKeysModel *> *aK = [self sjGetArrayCorrespondingKeys:[model class]];
    
    NSArray<NSString *> *fields = [self sjQueryTabAllFieldsWithClass:[model class]];
    [fields enumerateObjectsUsingBlock:^(NSString * _Nonnull fields, NSUInteger idx, BOOL * _Nonnull stop) {
        
        __block id appendValue = nil;
        __block BOOL addedBol = NO;
        
        if ( [fields isEqualToString:autoincrementPrimaryKeyModel.ownerFields] ) {
            id fieldsValue = [(id)model valueForKey:fields];
            /*!
             *  如果是自增主键. 等于 0 的情况下 表示是一条新增的数据。 直接跳到插入代码
             */
            if ( ![fieldsValue integerValue] ) goto _SJInsertValue;
        }
        
        if ( [model respondsToSelector:NSSelectorFromString(fields)] ) {
            id fieldsValue = [(id)model valueForKey:fields];
            if ( ![fieldsValue isKindOfClass:[NSArray class]] ) {
                appendValue = fieldsValue;
                addedBol = YES;
            }
        }
        
        if ( addedBol ) goto _SJInsertValue;
        
        if ( 0 != cK.count ) {
            
            [cK enumerateObjectsUsingBlock:^(SJDBMapCorrespondingKeyModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ( [fields isEqualToString:obj.correspondingFields] ) {
                    id cValue = [(id)model valueForKey:obj.ownerFields];
                    id cValueKeyValue = [cValue valueForKey:obj.correspondingFields];
                    appendValue = cValueKeyValue;
                    addedBol = YES;
                    *stop = YES;
                }
            }];
        }
        
        if ( addedBol ) goto _SJInsertValue;

        if ( 0 != aK.count ) {
            
            [aK enumerateObjectsUsingBlock:^(SJDBMapArrayCorrespondingKeysModel * _Nonnull ACKM, NSUInteger idx, BOOL * _Nonnull stop) {
                NSArray<id> *arrModels = [(id)model valueForKey:ACKM.ownerFields];
                if ( [fields isEqualToString:ACKM.ownerFields] && 0 != arrModels.count ) {
                    appendValue = [self sjGetArrModelPrimaryValues:arrModels].mutableCopy;;
                    addedBol = YES;
                    *stop = YES;
                }
            }];
        }

    _SJInsertValue:
        if ( !appendValue ) {
            [sqlM appendFormat:@"%@,", appendValue];
        }
        else if ( [appendValue isKindOfClass:[NSString class]] && [(NSString *)appendValue containsString:@"'"] )
            [sqlM appendFormat:@"\"%@\",", appendValue];
        else
            [sqlM appendFormat:@"'%@',", appendValue];
    }];
    
    [sqlM deleteCharactersInRange:NSMakeRange(sqlM.length - 1, 1)];
    [sqlM appendString:@")"];
    return sqlM;
}

/*!
 *  生成批量更新或插入数据
 */
- (NSString *)sjGetBatchInsertOrUpdateSubffixSQL:(NSArray<id<SJDBMapUseProtocol>> *)models {
    NSMutableString *subffixSQLM = [NSMutableString new];
    [models enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [subffixSQLM appendFormat:@"UNION ALL %@ ", [self sjGetInsertOrUpdateSuffixSQL:obj]];
    }];
    [subffixSQLM deleteCharactersInRange:NSMakeRange(0, @"UNION  ALL".length)];
    return subffixSQLM;
}

/*!
 *  获取一般的更新语句
 */
- (NSString *)sjGetCommonUpdateSQLWithFields:(NSArray<NSString *> *)fields model:(id<SJDBMapUseProtocol>)model {
//    update Person set name = 'xiaoMing', age = 21 where personID = 0;
    NSMutableString *sqlM = [NSMutableString stringWithFormat:@"UPDATE %@ SET ", [model class]];
    [fields enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id value = [(id)model valueForKey:obj];
        if ( [value isKindOfClass:[NSString class]] && [(NSString *)value containsString:@"'"] )
             [sqlM appendFormat:@"%@ = \"%@\",", obj, value];
        else [sqlM appendFormat:@"%@ = '%@',", obj, value];
    }];
    [sqlM deleteCharactersInRange:NSMakeRange(sqlM.length - 1, 1)];
    
    NSString *primaryFields = nil;
    
    if ( [self sjHasPrimaryKey:[model class]] ) {
        primaryFields = [self sjGetPrimaryFields:[model class]];
    }
    else if ( [self sjHasAutoPrimaryKey:[model class]] ) {
        primaryFields = [self sjGetAutoPrimaryFields:[model class]];
    }
    
    [sqlM appendFormat:@" where %@ = %@;", primaryFields, [(id)model valueForKey:primaryFields]];
    return sqlM.copy;
}

/*!
 *  生成删除Sql语句
 */
- (NSString *)sjGetDeleteSQL:(Class)cls uM:(SJDBMapUnderstandingModel *)uM deletePrimary:(NSInteger)primaryValue {
    /*!
     *  获取表名
     */
    NSString *tabName = [NSString stringWithUTF8String:[self sjGetTabName:cls]];
    if ( !tabName ) return nil;
    
    /*!
     *  获取主键
     */
    NSString *primaryKey = uM.primaryKey ? uM.primaryKey.ownerFields : uM.autoincrementPrimaryKey.ownerFields;
    
    /*!
     *  生成 SQL语句
     */
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = %zd;", tabName, primaryKey, primaryValue];
    
    return sql;
}

/*!
 *  生成批量删除Sql语句
 */
- (NSString *)sjGetBatchDeleteSQL:(Class)cls primaryValues:(NSArray<NSNumber *> *)primaryValues {
    const char *tabName = [self sjGetTabName:cls];
    NSString *primaryFields = [self sjGetPrimaryKey:cls].ownerFields;
    NSMutableString *sql = [NSMutableString stringWithFormat:@"DELETE FROM %s WHERE %@ in (", tabName, primaryFields];
    
    [primaryValues enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [sql appendFormat:@"%@, " , obj];
    }];
    [sql deleteCharactersInRange:NSMakeRange(sql.length - 2, 1)];
    [sql appendString:@");"];
    return sql;
}


/*!
 *  获取该类主键
 */
- (SJDBMapPrimaryKeyModel *)sjGetPrimaryKey:(Class)cls{
    NSString *key = [self _sjPerformClassMethod:cls sel:@selector(primaryKey) obj1:nil obj2:nil];
    if ( !key ) return nil;
    SJDBMapPrimaryKeyModel *model = [SJDBMapPrimaryKeyModel new];
    model.ownerCls = cls;
    model.ownerFields = key;
    return model;
}

/*!
 *  获取主键字段
 */
- (NSString *)sjGetPrimaryFields:(Class)cls {
    NSString *key = [self _sjPerformClassMethod:cls sel:@selector(primaryKey) obj1:nil obj2:nil];
    return key;
}

- (BOOL)sjHasPrimaryKey:(Class)cls {
    return [(id)cls respondsToSelector:@selector(primaryKey)];
}

/*!
 *  获取主键值
 */
- (NSNumber *)sjGetPrimaryValue:(id<SJDBMapUseProtocol>)model {
    NSString *primaryFields = [self sjGetPrimaryFields:[model class]];
    if ( 0 == primaryFields.length ) return nil;
    return [(id)model valueForKey:primaryFields];
}
/*!
 *  获取自增主键
 */
- (SJDBMapAutoincrementPrimaryKeyModel *)sjGetAutoincrementPrimaryKey:(Class)cls{
    NSString *key = [self _sjPerformClassMethod:cls sel:@selector(autoincrementPrimaryKey) obj1:nil obj2:nil];
    if ( !key ) return nil;
    SJDBMapAutoincrementPrimaryKeyModel *model = [SJDBMapAutoincrementPrimaryKeyModel new];
    model.ownerCls = cls;
    model.ownerFields = key;
    return model;
}

/*!
 *  获取自增主键字段
 */
- (NSString *)sjGetAutoPrimaryFields:(Class)cls {
    NSString *key = [self _sjPerformClassMethod:cls sel:@selector(autoincrementPrimaryKey) obj1:nil obj2:nil];
    return key;
}

/*!
 *  获取自增主键值
 */
- (NSNumber *)sjGetAutoPrimaryValue:(id<SJDBMapUseProtocol>)model {
    NSString *autoPrimaryFields = [self sjGetAutoPrimaryFields:[model class]];
    if ( 0 == autoPrimaryFields.length ) return nil;
    return [(id)model valueForKey:autoPrimaryFields];
}

/*!
 *  获取主键字段或自增主键字段
 */
- (NSString *)sjGetPrimaryOrAutoPrimaryFields:(Class)cls {
    NSString *fields = [self sjGetPrimaryFields:cls];
    return fields ? fields : [self sjGetAutoPrimaryFields:cls];
}

/*!
 *  获取主键值或者自增主键值
 */
- (NSNumber *)sjGetPrimaryOrAutoPrimaryValue:(id<SJDBMapUseProtocol>)model {
    NSNumber *value = [self sjGetPrimaryValue:model];
    return value ? value : [self sjGetAutoPrimaryValue:model];
}


- (BOOL)sjHasAutoPrimaryKey:(Class)cls {
    return [(id)cls respondsToSelector:@selector(autoincrementPrimaryKey)];
}

/*!
 *  获取数组相应键
 */
- (NSArray<SJDBMapArrayCorrespondingKeysModel *> *)sjGetArrayCorrespondingKeys:(Class)cls {
    NSDictionary<NSString *, Class> *keys = [self _sjPerformClassMethod:cls sel:@selector(arrayCorrespondingKeys) obj1:nil obj2:nil];
    if ( !keys ) return NULL;
    NSMutableArray<SJDBMapArrayCorrespondingKeysModel *> *modelsM = [NSMutableArray new];
    [keys enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class  _Nonnull obj, BOOL * _Nonnull stop) {
        SJDBMapArrayCorrespondingKeysModel *model = [SJDBMapArrayCorrespondingKeysModel new];
        model.ownerFields = key;
        model.ownerCls = cls;
        model.correspondingCls = obj;
        model.correspondingPrimaryKey = [self sjGetPrimaryKey:obj];
        model.correspondingAutoincrementPrimaryKey = [self sjGetAutoincrementPrimaryKey:obj];
        [modelsM addObject:model];
    }];
    return modelsM;
}

/*!
 *  dict keys
 */
- (NSArray<NSString *> *)sjGetArrCorrespondingOriginFields:(Class)cls {
    NSDictionary<NSString *, Class> *keys = [self _sjPerformClassMethod:cls sel:@selector(arrayCorrespondingKeys) obj1:nil obj2:nil];
    if ( !keys ) return NULL;
    return keys.allKeys;
}

/*!
 *  dict values
 */
- (NSArray<Class> *)sjGetArrCorrespondingFields:(Class)cls {
    NSDictionary<NSString *, Class> *keys = [self _sjPerformClassMethod:cls sel:@selector(arrayCorrespondingKeys) obj1:nil obj2:nil];
    if ( !keys ) return NULL;
    return keys.allValues;
}


/*!
 *  获取相应键
 */
- (NSArray<SJDBMapCorrespondingKeyModel *>*)sjGetCorrespondingKeys:(Class)cls {
    NSDictionary<NSString *,NSString *> *keys = [self _sjPerformClassMethod:cls sel:@selector(correspondingKeys) obj1:nil obj2:nil];
    if ( !keys ) return NULL;
    NSMutableArray<SJDBMapCorrespondingKeyModel *> *modelsM = [NSMutableArray new];
    [keys enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        SJDBMapCorrespondingKeyModel *model = [SJDBMapCorrespondingKeyModel new];
        model.ownerCls = cls;
        model.ownerFields = key;
        model.correspondingFields = obj;
        model.correspondingCls = [self _sjGetObjClass:model.ownerCls fields:model.ownerFields];
        [modelsM addObject:model];
    }];
    return modelsM;
}

/*!
 *  dict keys
 */
- (NSArray<NSString *> *)sjGetCorrespondingOriginFields:(Class)cls {
    NSDictionary<NSString *,NSString *> *keys = [self _sjPerformClassMethod:cls sel:@selector(correspondingKeys) obj1:nil obj2:nil];
    if ( !keys ) return NULL;
    return keys.allKeys;
}

/*!
 *  dict values
 */
- (NSArray<NSString *> *)sjGetCorrespondingFields:(Class)cls {
    NSDictionary<NSString *,NSString *> *keys = [self _sjPerformClassMethod:cls sel:@selector(correspondingKeys) obj1:nil obj2:nil];
    if ( !keys ) return NULL;
   return keys.allValues;
}

/*!
 *  获取表名称
 */
- (const char *)sjGetTabName:(Class)cls {
    return class_getName(cls);
}

/*!
 *  获取自增键最后一个ID. 根据ID排序, 获取最后一条数据的ID
 */
- (NSNumber *)sjGetLastDataIDWithClass:(Class)cls autoincrementPrimaryKeyModel:(SJDBMapAutoincrementPrimaryKeyModel *)aPKM {
    NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM %s ORDER by %@ desc limit 1;", aPKM.ownerFields, [self sjGetTabName:cls], aPKM.ownerFields];
    NSDictionary *dict = [self sjQueryWithSQLStr:sql].firstObject;
    if ( !dict && !dict.count ) return nil;
    NSString *fields = [self sjGetAutoPrimaryFields:cls];
    if ( 0 == fields.length ) return nil;
    return dict[fields];
}

/*!
 *  {"PersonTag":[0,1,2]}
 *  {"Goods":[13,14]}
 */
- (NSString *)sjGetArrModelPrimaryValues:(NSArray<id<SJDBMapUseProtocol>> *)cValues {
    if ( 0 == cValues.count ) return nil;
    NSMutableArray *primaryKeyValuesM = [NSMutableArray new];
    SJDBMapPrimaryKeyModel *pM = [self sjGetPrimaryKey:[cValues[0] class]];
    SJDBMapAutoincrementPrimaryKeyModel *aPM = [self sjGetAutoincrementPrimaryKey:[cValues[0] class]];
    NSAssert((pM || aPM), @"[%@] 该类没有设置主键或自增主键.", [cValues[0] class]);
    [cValues enumerateObjectsUsingBlock:^(id  _Nonnull value, NSUInteger idx, BOOL * _Nonnull stop) {
        /*!
         *  如果是主键
         */
        if ( pM ) [primaryKeyValuesM addObject:[value valueForKey:pM.ownerFields]];
        /*!
         *  如果是自增主键
         *  主键有值就更新, 没值就插入
         */
        if ( !aPM ) return ;
        __block id aPKV = [value valueForKey:aPM.ownerFields];
        if ( 0 != [aPKV integerValue] )
            [primaryKeyValuesM addObject:[value valueForKey:aPM.ownerFields]];
        else {
            SJDBMapUnderstandingModel *uM = [self sjGetUnderstandingWithClass:[value class]];
            [self sjInsertOrUpdateDataWithModel:value uM:uM];
            [primaryKeyValuesM addObject:[value valueForKey:aPM.ownerFields]];
        }
    }];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:@{NSStringFromClass([cValues[0] class]) : primaryKeyValuesM} options:0 error:nil];
    NSMutableString *strM = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding].mutableCopy;
    return strM;
}

/*!
 *  执行某个有返回值的类方法
 */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (id)_sjPerformClassMethod:(Class)cls sel:(SEL)sel obj1:(id)obj1 obj2:(id)obj2 {
    if ( ![(id)cls respondsToSelector:sel] ) return nil;
    return [(id)cls performSelector:sel withObject:obj1 withObject:obj2];
}
#pragma clang diagnostic pop

/*!
 *  获取某个变量的对应的类
 */
- (Class)_sjGetObjClass:(Class)ownerCls fields:(NSString *)fields {
    Ivar ivar = class_getInstanceVariable(ownerCls, [NSString stringWithFormat:@"_%@", fields].UTF8String);
    return _sjGetClass(ivar_getTypeEncoding(ivar));
}

/*!
 *  通过C类型获取类, 前提必须是对象类型
 */
static Class _sjGetClass(const char *cType) {
    if ( NULL == cType ) return NULL;
    if ( '@' != cType[0] ) return NULL;
    size_t ctl = strlen(cType);
    // 如果是 id 类型, 目前先跳过.
    if ( 1 == strlen(cType) && '@' == cType[0] ) return NULL;
    if ( '\"' != cType[1] ) return NULL;   // @?
    char *className = malloc(ctl);
    *className = '\0';
    for ( int j = 0 ; j < ctl - 3 ; j ++ ) className[j] = cType[j + 2];
    className[ctl - 3] = '\0';
    Class cls = objc_getClass(className);
    free(className);
    return cls;
}

//typedef NS_ENUM(NSUInteger, SJType) {
//    SJType_Integer,
//    SJType_UInteger,
//    SJType_Double,
//    SJType_CharStr,
//    SJType_Obj,
//};

//static SJType _sjGetSJType(Ivar ivar) {
//    const char *CType = ivar_getTypeEncoding(ivar);
//    char first = CType[0];
//    if      ( first == _C_INT ||        //  Int
//              first == _C_SHT ||        //  Short
//              first == _C_LNG_LNG ||    //  Long Long
//              first == _C_BFLD ||       //  bool
//              first == _C_BOOL )        //  BOOL
//        return SJType_Integer;
//    else if ( first == _C_UINT ||       //  Unsigned Int
//              first == _C_USHT ||       //  Unsigned Short
//              first == _C_ULNG_LNG ||   //  Unsigned Long
//              first == _C_ULNG_LNG )    //  Unsigned long long
//        return SJType_UInteger;
//    else if ( first == _C_DBL ||        //  double
//              first == _C_FLT )         //  float
//        return SJType_Double;
//    else if ( first == _C_CHARPTR )     //  char  *
//        return SJType_CharStr;
//    else
//        return SJType_Obj;
//}

/*!
 *  查询类中某个字段的C类型
 */
//static const char *_sjIvarCType(Class cls, const char *ivarName) {
//    if ( NULL == ivarName || NULL == cls ) return NULL;
//    Ivar ivar = class_getInstanceVariable(cls, ivarName);
//    return ivar_getTypeEncoding(ivar);
//}
//
///*!
// *  字典转模型
// */
//static id _sjGetModel(Class cls, NSDictionary *dict) {
//    // 获取所有变量名
//    unsigned int ivarCount = 0;
//    struct objc_ivar **ivarList = class_copyIvarList(cls, &ivarCount);
//
//    id model = [cls new];
//    for ( int i = 0 ; i < ivarCount ; i++ ) {
//        Ivar ivar = ivarList[i];
//        const char *ivarName = ivar_getName(ivar);
//        id value = dict[[NSString stringWithUTF8String:&ivarName[1]]];
//
//        SJType type = _sjGetSJType(ivar);
//        switch (type) {
//            case SJType_Integer:
//            case SJType_UInteger:
//            case SJType_Double:
//            {
//                [model setValue:value forKey:[NSString stringWithUTF8String:ivarName]];
//            }
//                break;
//            case SJType_Obj:
//            {
//                const char *oType = _sjIvarCType(cls, ivarName);
//
//                // NS
//                if ( 'N' == oType[2] && 'S' == oType[3] ) {
//                    [model setValue:value forKey:[NSString stringWithUTF8String:ivarName]];
//                    continue;
//                }
//
//                size_t ctl = strlen(oType);
//                // id 类型
//                if ( 1 == strlen(oType) && '@' == oType[0] ) {
//                    [model setValue:value forKey:[NSString stringWithUTF8String:ivarName]];
//                    continue;
//                }
//
//                // @?..@^..
//                if ( '\"' != oType[1] ) {
//                    if ( i == ivarCount - 1) break;
//                    continue;
//                }
//
//                char *className = malloc(ctl - 4);
//                *className = '\0';
//                for ( int j = 0 ; j < ctl - 3 ; j ++ ) className[j] = oType[j + 2];
//                className[ctl - 3] = '\0';
//                NSString *clsStr = [NSString stringWithUTF8String:className];
//                [model setValue:_sjGetModel(NSClassFromString(clsStr), value) forKey:[NSString stringWithUTF8String:ivarName]];
//                free(className);
//            }
//                break;
//            default:
//                break;
//        }
//    }
//
//    free(ivarList);
//
//    return model;
//}
@end
