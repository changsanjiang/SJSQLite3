//
//  SJDBMapQueryCache.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/9/6.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SJDBMapQueryCache.h"

@implementation SJDBMapModelCache

@synthesize memeryM = _memeryM;

- (NSMutableArray<id<SJDBMapUseProtocol>> *)memeryM {
    if ( _memeryM ) return _memeryM;
    _memeryM = [NSMutableArray array];
    return _memeryM;
}

@end



@implementation SJDBMapQueryCache

@synthesize modelCacheM = _modelCacheM;

- (NSMutableArray<SJDBMapModelCache *> *)modelCacheM {
    if ( _modelCacheM ) return _modelCacheM;
    _modelCacheM = [NSMutableArray new];
    return _modelCacheM;
}

- (void)dealloc {
    NSLog(@"%zd - %s", __LINE__, __func__);
}

@end
