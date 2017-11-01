//
//  SJDBMapCorrespondingKeyModel.h
//  SJProject
//
//  Created by BlueDancer on 2017/6/3.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SJDBMapCorrespondingKeyModel : NSObject

@property (nonatomic, strong) Class ownerCls;
@property (nonatomic, strong) NSString *ownerFields;
@property (nonatomic, strong) Class correspondingCls;
@property (nonatomic, strong) NSString *correspondingFields;

@end
