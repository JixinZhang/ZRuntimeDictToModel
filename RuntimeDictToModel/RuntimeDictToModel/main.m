//
//  main.m
//  RuntimeDictToModel
//
//  Created by WSCN on 26/07/2017.
//  Copyright © 2017 Jixin.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/message.h>
#import "NSObject+DictionaryToModel.h"
#import "Student.h"
#import "ZClass.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        NSLog(@"Hello, World!");
        
        NSDictionary *studentInfo = @{@"name" : @"Kobe Bryant",
                                      @"age" : @(18),
                                      @"height" : @(190),
                                      @"id" : @(20170726),
                                      @"gender" : @(1)};
        Student *student = [[Student alloc] init];
        [student setValuesForKeysWithDictionary:studentInfo];
        
        Student *student1 = [Student modelWithDict:studentInfo];
        NSLog(@"student = %@",student1);
        
        NSDictionary *classInfo = @{@"student" : studentInfo,
                                    @"title" : @"Math",
                                    @"subtitle" : @"Global",
                                    @"header" : @"Shanghai",
                                    @"dict" : studentInfo,
                                    @"item" : @[studentInfo,studentInfo,@"whatever"]};
        
        ZClass *class1 = [ZClass modelWithDict2:classInfo];
        NSLog(@"class1 = %@",class1);
    }
    return 0;
}
