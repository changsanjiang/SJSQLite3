//
//  SJSQLite3+SJSQLite3CollectionExtended.m
//  Pods-SJSQLite3_Example
//
//  Created by BlueDancer on 2019/8/29.
//

#import "SJSQLite3+SJSQLite3CollectionExtended.h"
#import "SJSQLiteTableModelConstraints.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    _SJElementTypeJson,
    _SJElementTypeObject,
} _SJElementType;

@interface _SJSQLiteCollectionElement : NSObject
+ (instancetype)elementWithCollection:(id)collection;

@property (nonatomic) NSInteger id;
@property (nonatomic) _SJElementType type;
@property (nonatomic, copy, nullable) NSString *collectionClass;
@property (nonatomic, copy, nullable) NSString *jsonData;
@property (nonatomic, copy, nullable) NSString *objectTable;
@property (nonatomic, copy, nullable) NSString *objectIds;
@end

@implementation _SJSQLiteCollectionElement
+ (nullable Class)elementClassForModelCollection:(id)collection {
    if ( [collection isKindOfClass:NSArray.class] ) {
        Class cls = [[(NSArray *)collection firstObject] class];
        if ( [cls respondsToSelector:@selector(sql_primaryKey)] )
            return cls;
    }
    if ( [collection isKindOfClass:NSSet.class] ) {
        Class cls = [[(NSSet *)collection anyObject] class];
        if ( [cls respondsToSelector:@selector(sql_primaryKey)] )
            return cls;
    }
    return nil;
}

+ (instancetype)elementWithCollection:(id)collection {
    _SJSQLiteCollectionElement *element = [_SJSQLiteCollectionElement new];
    element.collectionClass = NSStringFromClass([collection class]);
    Class _Nullable cls = [self elementClassForModelCollection:collection];
    if ( cls !=  nil ) {
        element.type = _SJElementTypeObject;
        element.objectTable = [cls respondsToSelector:@selector(sql_tableName)] ? [cls sql_tableName] : sqlite3_obj_get_default_table_name(cls);
        
        NSString *primaryKey = [cls sql_primaryKey];
        
        /// ......
        
    }
    else {
        element.type = _SJElementTypeJson;
        NSData *data = [NSJSONSerialization dataWithJSONObject:collection options:0 error:nil];
        element.jsonData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
//    element.collectionClass = NSStringFromClass([collection class]);
//
//    if ( [collection isKindOfClass:NSArray.class] && [[[collection firstObject] class] respondsToSelector:@selector(sql_primaryKey)] ) {
//        element.type = _SJElementTypeObject;
//        element.objectTable = NSStringFromClass([[collection firstObject] class]);
//    }
//    else {
//        用一张表去呈现这个数据结构
//
//        insert or replace
//
//        手撸sql + 插入
//    }
    return element;
}
@end


@implementation SJSQLite3 (SJSQLite3CollectionExtended)

- (BOOL)saveCollection:(id)collection forKey:(NSString *)key error:(NSError **)error {
    // 总表:
    // 子表:
    return NO;
}

- (nullable id)collectionForKey:(NSString *)key {
    /**
     集合中包含模型时:
     模型的种类不确定, 是动态的

     id key type json? table? ids?
     
     集合中包含基本数据类型或字符串时:
        - 转换为json字符串再存储.
     */
    return nil;
}

@end
NS_ASSUME_NONNULL_END
