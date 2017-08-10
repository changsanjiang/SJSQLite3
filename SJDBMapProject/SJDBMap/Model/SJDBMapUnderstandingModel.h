//
//  SJDBMapUnderstandingModel.h
//  SJProject
//
//  Created by BlueDancer on 2017/6/3.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJDBMapUseProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class SJDBMapPrimaryKeyModel, SJDBMapAutoincrementPrimaryKeyModel, SJDBMapCorrespondingKeyModel, SJDBMapArrayCorrespondingKeysModel;


@interface SJDBMapUnderstandingModel : NSObject<SJDBMapUseProtocol>

@property (nonatomic, assign) NSInteger uMID;
@property (nonatomic, assign, nonnull , readwrite) Class ownerCls;
@property (nonatomic, strong, nullable, readwrite) SJDBMapPrimaryKeyModel *primaryKey;
@property (nonatomic, strong, nullable, readwrite) SJDBMapAutoincrementPrimaryKeyModel *autoincrementPrimaryKey;
@property (nonatomic, strong, nullable, readwrite) NSArray<SJDBMapCorrespondingKeyModel *> *correspondingKeys;
@property (nonatomic, strong, nullable, readwrite) NSArray<SJDBMapArrayCorrespondingKeysModel *> *arrayCorrespondingKeys;

@end

NS_ASSUME_NONNULL_END
