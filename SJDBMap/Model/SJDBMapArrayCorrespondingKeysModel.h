//
//  SJDBMapArrayCorrespondingKeysModel.h
//  SJProject
//
//  Created by BlueDancer on 2017/6/3.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SJDBMapPrimaryKeyModel, SJDBMapAutoincrementPrimaryKeyModel;

@interface SJDBMapArrayCorrespondingKeysModel : NSObject

@property (nonatomic, assign) Class ownerCls;
@property (nonatomic, strong) NSString *ownerFields;
@property (nonatomic, assign) Class correspondingCls;
@property (nonatomic, strong) SJDBMapPrimaryKeyModel *correspondingPrimaryKey;
@property (nonatomic, strong) SJDBMapAutoincrementPrimaryKeyModel *correspondingAutoincrementPrimaryKey;

@end
