//
//  SJDBMapQueryCache.h
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/9/6.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SJDBMapUseProtocol;

NS_ASSUME_NONNULL_BEGIN

@interface SJDBMapModelCache : NSObject

@property (nonatomic, strong) NSString *className;
@property (nonatomic, strong, readonly) NSMutableArray<id<SJDBMapUseProtocol>> *memeryM;

@end

@interface SJDBMapQueryCache : NSObject

@property (nonatomic, strong, readonly) NSMutableArray<SJDBMapModelCache *> *modelCacheM;

@end

NS_ASSUME_NONNULL_END
