//
//  SJSQLite3+SJSQLite3Extended.m
//  Pods-SJSQLite3_Example
//
//  Created by 畅三江 on 2019/7/30.
//

#import "SJSQLite3+SJSQLite3Extended.h"
#import "SJSQLite3TableInfosCache.h"
#import "SJSQLiteErrors.h"

NS_ASSUME_NONNULL_BEGIN
@implementation SJSQLite3 (SJSQLite3Extended)
/// 获取满足指定条件的数据.
///
/// @param cls              数据库表所对应的类.
///
/// @param conditions       搜索条件.
///
/// @param orders           将结果排序. 例如: 将结果按id倒序和name倒序排列, 可传入
///                         @[[SJSQLite3ColumnOrder orderWithColumn:@"id" ascending:NO],
///                           [SJSQLite3ColumnOrder orderWithColumn:@"name" ascending:NO]]
///
/// @param error            执行出错. 当执行发生错误时, 会暂停执行后续的sql语句, 数据库将回滚到执行之前的状态.
///
/// @return                 返回满足条件的对象集合. 如果条件不满足, 则返回nil.
///
- (nullable NSArray *)objectsForClass:(Class)cls conditions:(nullable NSArray<SJSQLite3Condition *> *)conditions orderBy:(nullable NSArray<SJSQLite3ColumnOrder *> *)orders error:(NSError **)error {
    return [self objectsForClass:cls conditions:conditions orderBy:orders range:NSMakeRange(0, NSUIntegerMax) error:error];
}

/// 获取满足指定条件及指定数量的数据.(如果数据量过大, 可以使用此方法进行分页获取)
///
/// @param cls              数据库表所对应的类.
///
/// @param conditions       搜索条件.
///
/// @param orders           将结果排序. 例如: 将结果按id倒序和name倒序排列, 可传入
///                         @[[SJSQLite3ColumnOrder orderWithColumn:@"id" ascending:NO],
///                           [SJSQLite3ColumnOrder orderWithColumn:@"name" ascending:NO]]
///
/// @param error            执行出错. 当执行发生错误时, 会暂停执行后续的sql语句, 数据库将回滚到执行之前的状态.
///
/// @param range            限制返回的数据的数量.
///
/// @return                 返回满足条件的对象集合. 如果条件不满足, 则返回nil.
///
- (nullable NSArray *)objectsForClass:(Class)cls conditions:(nullable NSArray<SJSQLite3Condition *> *)conditions orderBy:(nullable NSArray<SJSQLite3ColumnOrder *> *)orders range:(NSRange)range error:(NSError **)error {
    SJSQLiteTableInfo *_Nullable table = [SJSQLite3TableInfosCache.shared getTableInfoForClass:cls];
    if ( table == nil ) {
        if ( error ) *error = sqlite3_error_get_table_failed(cls);
        return nil;
    }
    
    NSMutableString *where = nil;
    if ( conditions.count != 0 ) {
        where = NSMutableString.new;
        SJSQLite3Condition *last = conditions.lastObject;
        for ( SJSQLite3Condition *obj in conditions ) {
            [where appendString:obj.condition];
            if ( last != obj ) [where appendString:@" AND "];
        }
    }
    
    NSMutableString *orderBy = nil;
    if ( orders.count != 0 ) {
        orderBy = NSMutableString.new;
        SJSQLite3ColumnOrder *last = orders.lastObject;
        for ( SJSQLite3ColumnOrder *order in orders ) {
            [orderBy appendFormat:@"%@%@", order.order, last!=order?@",":@""];
        }
    }
    
    NSString *limit = nil;
    if ( range.length != NSUIntegerMax ) {
        limit = [NSString stringWithFormat:@"%ld, %ld", (long)range.location, (long)range.length];
    }

    NSMutableString *sql = NSMutableString.new;
    [sql appendFormat:@"SELECT * FROM '%@'", table.name];
    if ( where ) [sql appendFormat:@" WHERE %@", where];
    if ( orderBy ) [sql appendFormat:@" ORDER BY %@", orderBy];
    if ( limit ) [sql appendFormat:@" LIMIT %@", limit];
    [sql appendString:@";"];
    
    NSError *inner_error = nil;
    __auto_type results = [self exec:sql error:&inner_error];
    if ( inner_error != nil ) {
        if ( error ) *error = inner_error;
        return nil;
    }
    return [self objectsForClass:cls rowDatas:results error:error];
}

/// 查询数量
///
/// @param cls              数据库表所对应的类.
///
/// @param conditions       搜索条件.
///
/// @param error            执行出错. 当执行发生错误时, 会暂停执行后续的sql语句, 数据库将回滚到执行之前的状态.
///
/// @return                 返回满足条件的数据的数量.
- (NSUInteger)countOfObjectsForClass:(Class)cls conditions:(nullable NSArray<SJSQLite3Condition *> *)conditions error:(NSError **)error {
    SJSQLiteTableInfo *_Nullable table = [SJSQLite3TableInfosCache.shared getTableInfoForClass:cls];
    if ( table == nil ) {
        if ( error ) *error = sqlite3_error_get_table_failed(cls);
        return 0;
    }
    
    NSMutableString *where = nil;
    if ( conditions.count != 0 ) {
        where = NSMutableString.new;
        SJSQLite3Condition *last = conditions.lastObject;
        for ( SJSQLite3Condition *obj in conditions ) {
            [where appendString:obj.condition];
            if ( last != obj ) [where appendString:@" AND "];
        }
    }
    
    NSMutableString *sql = NSMutableString.new;
    [sql appendFormat:@"SELECT count(*) FROM '%@'", table.name];
    if ( where ) [sql appendFormat:@" WHERE %@", where];
    [sql appendString:@";"];
    
    NSError *inner_error = nil;
    __auto_type results = [self exec:sql error:&inner_error];
    if ( inner_error != nil ) {
        if ( error ) *error = inner_error;
        return 0;
    }
    return [results.firstObject[@"count(*)"] integerValue];
}
@end

@implementation SJSQLite3Condition
/// 条件操作符
///
/// @param  column          指定比较的列名.
///
/// @param  relation        指定`SJSQLite3Relation`中的任意值(>=, <=, !=, =, >, <).
///
/// @param  value           指定比较的值.
///
/// \code
/// // 例如查询`price = 12.0`的商品, 创建条件如下:
/// SJSQLite3Condition *cond =[SJSQLite3Condition conditionWithColumn:@"price" relatedBy:SJSQLite3RelationEqual value:@(12.0)];
/// NSArray *results = [SJSQLite3.shared objectsForClass:Product.class conditions:@[cond] orderBy:nil error:NULL];
/// \endcode
///
+ (instancetype)conditionWithColumn:(NSString *)column relatedBy:(SJSQLite3Relation)relation value:(id)value {
//    WHERE prod_price = 5;
    NSMutableString *conds = NSMutableString.new;
    [conds appendFormat:@"\"%@\" ", column];
    switch ( relation ) {
        case SJSQLite3RelationLessThanOrEqual:
            [conds appendFormat:@"<= '%@'", sqlite3_obj_filter_obj_value(value)];
            break;
        case SJSQLite3RelationEqual:
            [conds appendFormat:@"= '%@'", sqlite3_obj_filter_obj_value(value)];
            break;
        case SJSQLite3RelationGreaterThanOrEqual:
            [conds appendFormat:@">= '%@'", sqlite3_obj_filter_obj_value(value)];
            break;
        case SJSQLite3RelationUnequal:
            [conds appendFormat:@"!= '%@'", sqlite3_obj_filter_obj_value(value)];
            break;
        case SJSQLite3RelationLessThan:
            [conds appendFormat:@"> '%@'", sqlite3_obj_filter_obj_value(value)];
            break;
        case SJSQLite3RelationGreaterThan:
            [conds appendFormat:@"< '%@'", sqlite3_obj_filter_obj_value(value)];
            break;
    }
    return [[SJSQLite3Condition alloc] initWithCondition:conds];
}

/// IN操作符 指定一组值, 匹配其中的任意值
///
/// @param  column          指定比较的列名.
///
/// @param  values          指定一组值, 匹配其中的任意值.
///
/// \code
/// // 例如查询`price = 12.0 或 price = 9.0`的商品, 创建条件如下:
/// SJSQLite3Condition *cond =[SJSQLite3Condition conditionWithColumn:@"price" in:@[@(12.0), @(9.0)]];
/// NSArray *results = [SJSQLite3.shared objectsForClass:Product.class conditions:@[cond] orderBy:nil error:NULL];
/// \endcode
///
+ (instancetype)conditionWithColumn:(NSString *)column in:(NSArray *)values {
//    WHERE prod_price IN (3.49, 5);
    NSMutableString *conds = NSMutableString.new;
    [conds appendFormat:@"\"%@\" IN (", column];
    id last = values.lastObject;
    for ( id value in values ) {
        [conds appendFormat:@"'%@'%@", sqlite3_obj_filter_obj_value(value), last!=value?@",":@""];
    }
    [conds appendString:@")"];
    return [[SJSQLite3Condition alloc] initWithCondition:conds];
}

/// BETWEEN操作符 用来匹配某个范围的值
///
/// @param  column          指定比较的列名.
///
/// @param  start           范围的开始
///
/// @param  end             范围的结束
///
/// \code
/// // 例如查询`3.49 和 5.0 之间`的商品, 创建条件如下:
/// SJSQLite3Condition *cond =[SJSQLite3Condition conditionWithColumn:@"price" between:@(3.49) and:@(5.0)];
/// NSArray *results = [SJSQLite3.shared objectsForClass:Product.class conditions:@[cond] orderBy:nil error:NULL];
/// \endcode
///
+ (instancetype)conditionWithColumn:(NSString *)column between:(id)start and:(id)end {
//    WHERE prod_price BETWEEN 3.49 AND 5;
    NSMutableString *conds = NSMutableString.new;
    [conds appendFormat:@"(\"%@\" BETWEEN ", column];
    [conds appendFormat:@"%@", sqlite3_obj_filter_obj_value(start)];
    [conds appendString:@" AND "];
    [conds appendFormat:@"%@", sqlite3_obj_filter_obj_value(end)];
    [conds appendFormat:@")"];
    return [[SJSQLite3Condition alloc] initWithCondition:conds];
}

/// 空值匹配
///
/// @param  column          指定比较的列名.
///
+ (instancetype)conditionWithIsNullColumn:(NSString *)column {
//    WHERE prod_desc IS NULL;
    return [[SJSQLite3Condition alloc] initWithCondition:[NSString stringWithFormat:@"%@ IS NULL", column]];
}
/// 自定义查询条件
///
/// 例如 进行模糊查询:
///
///    name LIKE '200%'     查找以 200 开头的任意值
///
///    name LIKE '%200%'    查找任意位置包含 200 的任意值
///
///    name LIKE '_00%'     查找第二位和第三位为 00 的任意值
///
///    name LIKE '2_%_%'    查找以 2 开头，且长度至少为 3 个字符的任意值
///
///    name LIKE '%2'       查找以 2 结尾的任意值
///
///    name LIKE '_2%3'     查找第二位为 2，且以 3 结尾的任意值
///
///    name LIKE '2___3'    查找长度为 5 位数，且以 2 开头以 3 结尾的任意值
///
- (instancetype)initWithCondition:(NSString *)condition {
    self = [super init];
    if ( self ) {
        _condition = condition.copy;
    }
    return self;
}
@end

@implementation SJSQLite3ColumnOrder
+ (instancetype)orderWithColumn:(NSString *)column ascending:(BOOL)ascending {
    return [[self alloc] initWithColumn:column ascending:ascending];
}
- (instancetype)initWithColumn:(NSString *)column ascending:(BOOL)ascending {
    self = [super init];
    if ( !self ) return nil;
    _order = [NSString stringWithFormat:@"\"%@\" %@", column, ascending?@"ASC":@"DESC"];
    return self;
}
@end
NS_ASSUME_NONNULL_END
