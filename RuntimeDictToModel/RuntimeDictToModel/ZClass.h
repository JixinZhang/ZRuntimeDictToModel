//
//  ZClass.h
//  RuntimeDemo
//
//  Created by WSCN on 25/07/2017.
//  Copyright © 2017 Jixin.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Student.h"

@interface ZClass : NSObject

@property (nonatomic, strong) Student *student;
@property (nonatomic, strong) NSArray *item;
@property (nonatomic, strong) NSDictionary *dict;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *header;

@end
