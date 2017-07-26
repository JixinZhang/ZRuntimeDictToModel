### 写在前面的话

这篇文章的通过runtime实现字典转模型是参考(抄袭)[iOS 模式详解—「runtime面试、工作」看我就 🐒 了 ^_^.](http://www.jianshu.com/p/19f280afcb24)中runtime 字典转模型，并且在此基础上做了以下扩展：

1. 添加：属性名映射到字典中对应的key的方法，如id -> ID;
2. 修复：当模型中的数组中不全是某一个模型的时候，会引起崩溃的问题。如数组中有8个元素，其中7个是模型，还有一个是字符串；

### [Github 传送门](https://github.com/JixinZhang/ZRuntimeDictToModel)


**需要考虑一下三种情况** 

_点击可直接跳往对应小结_

* [当字典中的key和模型的属性匹配不上；](#2)
* [模型中嵌套模型（模型的属性是另外一个模型对象）；](#3)
* [模型中的数组中装着模型（数组中的元素是一个模型）。](#4)

## 一、使用runtime将字典转成模型

### 1. 思路
>使用runtime遍历出模型中的所有属性，根据模型中属性,去字典中取出对应的value给模型属性赋值

### 2. 代码

#### 1) 定义一个Student的模型，其属性如下：

Student.h文件

```
#import <Foundation/Foundation.h>

@interface Student : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSNumber *age;
@property (nonatomic, strong) NSNumber *height;
@property (nonatomic, strong) NSNumber *ID;


@end
```
Student.m文件

```
@implementation Student

@end
```

#### 2)对NSObject扩展一个分类NSObject+DictionaryToModel

NSObject+DictionaryToModel.h文件

```
+ (instancetype)modelWithDict:(NSDictionary *)dict;
```

NSObject+DictionaryToModel.m文件，**一定要导入<objc/message.h>**

```
#import "NSObject+DictionaryToModel.h"
#import <objc/message.h>
@implementation NSObject (DictionaryToModel)
/*
 *  根据模型中属性，去字典中取出对应的value并赋值给模型的属性
 *  遍历取出所有属性
 */
+ (instancetype)modelWithDict:(NSDictionary *)dict {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    //1. 创建对应的对象
    id objc = [[self alloc] init];
    
    //2. 利用runtime给对象中的属性赋值
    /*
     Ivar: 成员变量；
     class_copyIvarList(): 获取类中的所有成员变量；
     第一个参数：表示获取哪个类的成员变量；
     第二个参数：表示这个类有多少成员变量；
     返回值Ivar *：指的是一个ivar数组，会把所有成员变量放在一个数组中，通过返回数组就全部获取到。
     count: 成员变量个数
     */
    unsigned int count = 0;
    Ivar *ivarList = class_copyIvarList(self, &count);
    
    for (int i = 0; i < count; i++) {
        Ivar ivar = ivarList[i];
        // 获取成员变量名字
        NSString *ivarName = [NSString stringWithUTF8String:ivar_getName(ivar)];
        
        // 处理成员变量名->字典中的key(去掉 _ ,从第一个角标开始截取)
        NSString *key = [ivarName substringFromIndex:1];
        
        // 根据成员属性名去字典中查找对应的value
        id value = dict[key];
        
        if (value) {
            [objc setValue:value forKey:key];
        }
    }
    
    return objc;
}

@end
```

#### 3)调用`+ (instancetype)modelWithDict:(NSDictionary *)dict`

```

#import "Student.h"
#import "NSObject+DictionaryToModel.h"
......

NSDictionary *studentInfo = @{@"name" : @"Kobe Bryant",
                              @"age" : @(18),
                              @"height" : @(190),
                              @"id" : @(20160101),
                              @"gender" : @(1)};
Student *student = [Student modelWithDict2:studentInfo];
NSLog(@"student = %@", student);

```

#### 4)模型的转换结果

![image1.png](http://upload-images.jianshu.io/upload_images/2409226-a75993f7eefe7d74.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

**从上图可以看出**

* `student.ID`没有赋值成功，是因为在数据中没有`ID`这个key(Objective-C 中`id`是保留字，所以student的属性这里只能用`ID`)
* 对于这种模型属性名和数据中key不对应的问题，接下来会讲如何解决。

<h3 id="2"></h3>
## 二、当字典中的key和模型的属性匹配不上

### 1. 思路
>如果字典中的key和模型的属性匹配不上，可以做一个映射。将属性名映射到字典中对应的key上

### 2. 代码
这里代码接着上面的代码使用

#### 1）在NSObject的分类NSObject+DictionaryToModel中添加映射方法

NSObject+DictionaryToModel.h文件中

```
+ (NSDictionary *)modelCustomPropertyMapper;

```

NSObject+DictionaryToModel.m文件中

```
#import "NSObject+DictionaryToModel.h"
#import <objc/message.h>
@implementation NSObject (DictionaryToModel)
/*
 *  根据模型中属性，去字典中取出对应的value并赋值给模型的属性
 *  遍历取出所有属性
 */
+ (instancetype)modelWithDict:(NSDictionary *)dict {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    //1. 创建对应的对象
    id objc = [[self alloc] init];
    
    //2. 利用runtime给对象中的属性赋值
    /*
     Ivar: 成员变量；
     class_copyIvarList(): 获取类中的所有成员变量；
     第一个参数：表示获取哪个类的成员变量；
     第二个参数：表示这个类有多少成员变量；
     返回值Ivar *：指的是一个ivar数组，会把所有成员变量放在一个数组中，通过返回数组就全部获取到。
     count: 成员变量个数
     */
    unsigned int count = 0;
    Ivar *ivarList = class_copyIvarList(self, &count);
    
    for (int i = 0; i < count; i++) {
        Ivar ivar = ivarList[i];
        // 获取成员变量名字
        NSString *ivarName = [NSString stringWithUTF8String:ivar_getName(ivar)];
        
        // 处理成员变量名->字典中的key(去掉 _ ,从第一个角标开始截取)
        NSString *key = [ivarName substringFromIndex:1];
        
        // 根据成员属性名去字典中查找对应的value
        id value = dict[key];
        
        //如果通过属性名取不到对应的value，则更换属性名对应的映射名来取值
        if (!value) {
            NSDictionary *customKeyDict = [self modelCustomPropertyMapper];
            NSString *customKey = customKeyDict[key];
            value = dict[customKey];
        }
        
        if (value) {
            [objc setValue:value forKey:key];
        }
    }
    
    return objc;
}

//这里放一个空的字典，真正实现这个映射方法的地方是在模型中，模型中会将此方法重写
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{};
}

@end

```

#### 2）在模型中实现映射方法

```
//重写NSObject+DictionaryToModel分类中的映射方法
+ (NSDictionary *)modelCustomPropertyMapper {
    return @{@"ID" : @"id"};
}

```

#### 3）模型转换的结果如下

![image2.png](http://upload-images.jianshu.io/upload_images/2409226-96df3e26ae31ceaf.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

<h3 id="3"></h3>
## 三、模型中嵌套模型

### 1. 思路
>模型中嵌套模型就是字典中嵌套字典，当给模型的模型赋值的时候，再调用一次字典转模型就可以了。其实就是递归调用


### 2. 代码

#### 1) 定义一个ZClass模型，其属性具体如下：

ZClass.h文件中，包含了Student模型。

```
#import <Foundation/Foundation.h>
#import "Student.h"

@interface ZClass : NSObject

@property (nonatomic, strong) Student *student;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *header;

@end

```

ZClass.m文件中

```
#import "ZClass.h"
#import "NSObject+DictionaryToModel.h"

@implementation ZClass

@end

```

#### 2) 在NSObject的分类NSObject+DictionaryToModel中
完善一下`+ (instancetype)modelWithDict:(NSDictionary *)dict`方法，这里我写在`+ (instancetype)modelWithDict2:(NSDictionary *)dict`中。

NSObject+DictionaryToModel.h文件

```
+ (instancetype)modelWithDict2:(NSDictionary *)dict;
```

NSObject+DictionaryToModel.m文件，**一定要导入<objc/message.h>**

```
+ (instancetype)modelWithDict2:(NSDictionary *)dict {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    id objc = [[self alloc] init];
    
    unsigned int count = 0;
    Ivar *ivarList = class_copyIvarList(self, &count);
    
    for (int i = 0; i < count; i++) {
        Ivar ivar = ivarList[i];
        
        NSString *ivarName = [NSString stringWithUTF8String:ivar_getName(ivar)];
        // 获取成员变量类型
        NSString *ivarType = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivar)];
        
        // 替换: @\"Student\" -> Student
        ivarType = [ivarType stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        ivarType = [ivarType stringByReplacingOccurrencesOfString:@"@" withString:@""];
        
        NSString *key = [ivarName substringFromIndex:1];
        
        id value = dict[key];
        if (!value) {
            NSDictionary *customKeyDict = [self modelCustomPropertyMapper];
            NSString *customKey = customKeyDict[key];
            value = dict[customKey];
        }
        
        //如果value是一个字典，并且其类型是自定义对象才需要转换。不是OC中的数据类型，如：NSString, NSArray, NSDictionary, NSMutableArray, NSMutableDictionary, NSNumber等
        if ([value isKindOfClass:[NSDictionary class]] && ![ivarType hasPrefix:@"NS"]) {
            Class modelClass = NSClassFromString(ivarType);
            
            if (modelClass) {
				   //如果modelClass存在，则进入递归调用
                value = [modelClass modelWithDict2:value];
            }
        }
        if (value) {
            [objc setValue:value forKey:key];
        }
    }
    
    return objc;
}

```

#### 3）调用`+ (instancetype)modelWithDict2:(NSDictionary *)dict`

```
NSDictionary *classInfo = @{@"student" : studentInfo,
                                    @"title" : @"Math",
                                    @"subtitle" : @"Global",
                                    @"header" : @"Shanghai"};
        
ZClass *class1 = [ZClass modelWithDict2:classInfo];
NSLog(@"maxModel = %@",class1);
```

#### 4）模型转换的结果如下

![image3.png](http://upload-images.jianshu.io/upload_images/2409226-af32a1cd93ed3976.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

<h3 id="4"></h3>
## 四、模型中的数组中装着模型

### 1. 思路
>数组中装着模型，就是数组中的元素是一个字典。而这个字典对应着一个模型。在for循环数组的时候得到一个个字典，但是却不知道这个字典对应的模型是什么，所以需要告诉赋值的地方，数组中装的到底是什么模型，即模型的名称。

### 2. 代码
这里代码接着上面第三节的代码使用

#### 1）在NSObject的分类NSObject+DictionaryToModel中添加 数组中包含模型名称的方法

在NSObject+DictionaryToModel.h文件中

```
+ (NSDictionary *)arrayContainModelClass;

```

在NSObject+DictionaryToModel.m文件中

```
+ (instancetype)modelWithDict2:(NSDictionary *)dict {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    id objc = [[self alloc] init];
    
    unsigned int count = 0;
    Ivar *ivarList = class_copyIvarList(self, &count);
    
    for (int i = 0; i < count; i++) {
        Ivar ivar = ivarList[i];
        
        NSString *ivarName = [NSString stringWithUTF8String:ivar_getName(ivar)];
        NSString *ivarType = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivar)];
        
        ivarType = [ivarType stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        ivarType = [ivarType stringByReplacingOccurrencesOfString:@"@" withString:@""];
        
        NSString *key = [ivarName substringFromIndex:1];
        
        id value = dict[key];
        if (!value) {
            NSDictionary *customKeyDict = [self modelCustomPropertyMapper];
            NSString *customKey = customKeyDict[key];
            value = dict[customKey];
        }
        
        if ([value isKindOfClass:[NSDictionary class]] && ![ivarType hasPrefix:@"NS"]) {
            Class modelClass = NSClassFromString(ivarType);
            
            if (modelClass) {
                value = [modelClass modelWithDict2:value];
            }
        }
        
        if ([value isKindOfClass:[NSArray class]]) {
            if ([self respondsToSelector:@selector(arrayContainModelClass)]) {
                // 转换成id类型，就能调用任何对象的方法
                id idSelf = self;
                // 获取数组中字典对应的模型
                NSString *type =  [idSelf arrayContainModelClass][key];
                if (type) {
                    // 生成模型
                    Class classModel = NSClassFromString(type);
                    NSMutableArray *arrM = [NSMutableArray array];
                    // 遍历字典数组，生成模型数组
                    for (NSDictionary *dict in value) {
                        // 字典转模型
                        id model =  [classModel modelWithDict2:dict];
                        if (model) {
                            [arrM addObject:model];
                        } else {
                            //如果数组中的某个元素并不是个字典，则不做解析
                            [arrM addObject:dict];
                        }
                    }
                    // 把模型数组赋值给value
                    value = arrM;
                }
            }
        }
        
        if (value) {
            [objc setValue:value forKey:key];
        }
    }
    
    return objc;
}

//这里放一个空的字典，真正实现这个方法的地方是在模型中，模型中会将此方法重写
+ (NSDictionary *)arrayContainModelClass {
    return @{};
}

```

#### 2) 定义一个ZClass模型，其属性具体如下：

ZClass.h文件中，包含了Student模型。

```
#import <Foundation/Foundation.h>
#import "Student.h"

@interface ZClass : NSObject

@property (nonatomic, strong) Student *student;
@property (nonatomic, strong) NSArray *item;   //item中包含了Student类
@property (nonatomic, strong) NSDictionary *dict;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *header;

@end

```

ZClass.m文件中

```
#import "ZClass.h"
#import "NSObject+DictionaryToModel.h"

@implementation ZClass

+ (NSDictionary *)arrayContainModelClass {
    return @{@"item" : @"Student"};
}

@end

```

#### 3）调用`+ (instancetype)modelWithDict2:(NSDictionary *)dict`

```
NSDictionary *classInfo = @{@"student" : studentInfo,
                                    @"title" : @"Math",
                                    @"subtitle" : @"Global",
                                    @"header" : @"Shanghai",
                                    @"dict" : studentInfo,
                                    @"item" : @[studentInfo,studentInfo,@"whatever"]};
        
        ZClass *class1 = [ZClass modelWithDict2:classInfo];
        NSLog(@"maxModel = %@",class1);
```

#### 4）模型转换的结果如下

![image4.png](http://upload-images.jianshu.io/upload_images/2409226-695d6fb3834d3079.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### [Github 传送门](https://github.com/JixinZhang/ZRuntimeDictToModel)