//
//  Book.m
//  SJDBMapProject
//
//  Created by BlueDancer on 2017/6/5.
//  Copyright © 2017年 SanJiang. All rights reserved.
//

#import "Book.h"
#import <YYKit.h>

@implementation Book

+ (instancetype)bookWithID:(NSInteger)bid name:(NSString *)name {
    Book *book = [Book new];
    book.bookID = bid;
    book.name = name;
    return book;
}

// MARK: SJDBUserProtocol

+ (NSString *)primaryKey {
    return @"bookID";
}

@end
