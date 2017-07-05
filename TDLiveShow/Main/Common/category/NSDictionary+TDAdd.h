//
//  NSDictionary+TDAdd.h
//  TuanDaiV4
//
//  Created by WuSiJun on 2017/3/14.
//  Copyright © 2017年 Dee. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (TDAdd)

/**
 通过key 取值

 @param aKey key

 @return value
 */
- (id)td_ObjectForKey:(id)aKey;


/**
 通过key 取值，返回string

 @param aKey key

 @return value
 */
- (NSString *)td_StringForKey:(id)aKey;


/**
 通过key 取值，返回number

 @param aKey key

 @return value
 */
- (NSNumber *)td_NumberForKey:(id)aKey;


/**
 通过key 取值 返回int

 @param aKey key

 @return value
 */
- (NSInteger)td_IntegerForKey:(id)aKey;


/**
 通过key 取值 返回long,long

 @param aKey key

 @return value
 */
- (long long)td_LonglongForKey:(id)aKey;


/**
 通过key 取值 返回bool

 @param aKey key

 @return value
 */
- (BOOL)td_BoolForKey:(id)aKey;


/**
 通过key 取值，返回array

 @param aKey key

 @return value
 */
- (NSArray *)td_ArrayForKey:(id)aKey;


/**
 通过key 取值， 返回dict

 @param aKey key

 @return value
 */
- (NSDictionary *)td_dictionaryForKey:(id)aKey;

@end


@interface NSMutableDictionary (TDAdd)


/**
 设置某个值 for key

 @param anObject 对象
 @param aKey     key
 */
- (void)td_SetObjectSafe:(id)anObject forKey:(id<NSCopying>)aKey;

@end
