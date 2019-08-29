//
//  SJSQLite3+SJSQLite3CollectionExtended.h
//  Pods-SJSQLite3_Example
//
//  Created by BlueDancer on 2019/8/29.
//

#import "SJSQLite3.h"

NS_ASSUME_NONNULL_BEGIN
///
///
///
///
@interface SJSQLite3 (SJSQLite3CollectionExtended)

- (BOOL)saveCollection:(id)collection forKey:(NSString *)key error:(NSError **)error;

- (nullable id)collectionForKey:(NSString *)key;

@end
NS_ASSUME_NONNULL_END
