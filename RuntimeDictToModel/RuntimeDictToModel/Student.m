//
//  Student.m
//  RuntimeDemo
//
//  Created by WSCN on 24/07/2017.
//  Copyright © 2017 Jixin.com. All rights reserved.
//

#import "Student.h"
#import "NSObject+DictionaryToModel.h"

@implementation Student

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {
        self.ID = value;
    }
}

+ (NSDictionary *)modelCustomPropertyMapper {
    return @{@"ID" : @"id"};
}

@end
