//
//  SJSQLite3+SJSQLite3Extended.h
//  Pods-SJSQLite3_Example
//
//  Created by 畅三江 on 2019/7/30.
//
//  这里将会是对 SJSQLite3 的扩展.
//

#import "SJSQLite3.h"
@class SJSQLite3ColumnOrder, SJSQLite3Condition;


NS_ASSUME_NONNULL_BEGIN
@interface SJSQLite3 (SJSQLite3Extended)

- (nullable NSArray *)objectsForClass:(Class)cls conditions:(nullable NSArray<SJSQLite3Condition *> *)conditions orderBy:(nullable NSArray<SJSQLite3ColumnOrder *> *)orders error:(NSError **)error;

- (nullable NSArray *)objectsForClass:(Class)cls conditions:(nullable NSArray<SJSQLite3Condition *> *)conditions orderBy:(nullable NSArray<SJSQLite3ColumnOrder *> *)orders range:(NSRange)range error:(NSError **)error;

- (NSUInteger)countOfObjectsForClass:(Class)cls conditions:(nullable NSArray<SJSQLite3Condition *> *)conditions error:(NSError **)error;
@end

#pragma mark -

typedef enum : NSInteger {
    SJSQLite3RelationLessThanOrEqual = -1,
    SJSQLite3RelationEqual,
    SJSQLite3RelationGreaterThanOrEqual,
    SJSQLite3RelationUnequal,
    
    SJSQLite3RelationLessThan,
    SJSQLite3RelationGreaterThan,
} SJSQLite3Relation;

/// WHERE
///
@interface SJSQLite3Condition : NSObject
+ (instancetype)conditionWithColumn:(NSString *)column relatedBy:(SJSQLite3Relation)relation value:(id)value;
+ (instancetype)conditionWithColumn:(NSString *)column in:(NSArray *)values;
+ (instancetype)conditionWithColumn:(NSString *)column between:(id)start and:(id)end;
+ (instancetype)conditionWithIsNullColumn:(NSString *)column;
- (instancetype)initWithCondition:(NSString *)condition;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@property (nonatomic, copy, readonly) NSString *condition;
@end

/// ORDER BY
///
@interface SJSQLite3ColumnOrder : NSObject
+ (instancetype)orderWithColumn:(NSString *)column ascending:(BOOL)ascending;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@property (nonatomic, copy, readonly) NSString *order;
@end
NS_ASSUME_NONNULL_END
