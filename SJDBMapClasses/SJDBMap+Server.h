//
//  SJDBMap+Server.h
//  SJProject
//
//  Created by BlueDancer on 2017/6/3.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "SJDBMap.h"

extern char *_sjmystrcat(char *dst, const char *src);

@interface SJDBMap (Server)

/*!
 *  创建或更新一个表
 */
- (BOOL)sjCreateOrAlterTabWithClass:(Class)cls;

/*!
 *  自动创建相关的表
 */
- (void)sjAutoCreateOrAlterRelevanceTabWithClass:(Class)cls;

/*!
 *  查询表中的所有字段
 */
- (NSMutableArray<NSString *> *)sjQueryTabAllFieldsWithClass:(Class)cls;

@end
