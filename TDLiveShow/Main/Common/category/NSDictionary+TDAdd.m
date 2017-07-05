//
//  NSDictionary+TDAdd.m
//  TuanDaiV4
//
//  Created by WuSiJun on 2017/3/14.
//  Copyright © 2017年 Dee. All rights reserved.
//

#import "NSDictionary+TDAdd.h"

@implementation NSDictionary (TDAdd)

- (id)td_ObjectForKey:(id)aKey {
    if (!aKey) {
        TDLog(@"key 不能为nil");
        return nil;
    }
    return [self objectForKey:aKey];
}

- (NSString *)td_StringForKey:(id)aKey {
    NSString *value = [self td_ObjectForKey:aKey];
    if (value && ![value isKindOfClass:[NSNull class]]) {
        if ([value isKindOfClass:[NSString class]]) {
            return value;
        } else if ([value isKindOfClass:[NSNumber class]]) {
            return [NSString stringWithFormat:@"%@", value];
        }
        return nil;
    }
    return nil;
}

- (NSNumber *)td_NumberForKey:(id)aKey {
    NSNumber *value = [self td_ObjectForKey:aKey];
    if (value && ![value isKindOfClass:[NSNull class]]) {
        if ([value isKindOfClass:[NSNumber class]]) {
            return value;
        }
        else if ([value respondsToSelector:@selector(doubleValue)]) {
            return [NSNumber numberWithDouble:[value doubleValue]];
        }
        return nil;
    }
    return nil;
}

- (NSInteger)td_IntegerForKey:(id)aKey {
    NSString *value = [self td_ObjectForKey:aKey];
    if (value && [value respondsToSelector:@selector(integerValue)]) {
        return [value integerValue];
    }
    return 0;
}

- (long long)td_LonglongForKey:(id)aKey {
    NSString *value = [self td_ObjectForKey:aKey];
    if (value && [value respondsToSelector:@selector(longLongValue)]) {
        return [value longLongValue];
    }
    return 0;
}

- (BOOL)td_BoolForKey:(id)aKey {
    NSString *value = [self td_ObjectForKey:aKey];
    if (value && [value respondsToSelector:@selector(boolValue)]) {
        return [value boolValue];
    }
    return false;
}

- (NSArray *)td_ArrayForKey:(id)aKey {
    NSArray *value = [self td_ObjectForKey:aKey];
    if (value && [value isKindOfClass:[NSArray class]]) {
        return value;
    }
    return nil;
}

- (NSDictionary *)td_dictionaryForKey:(id)aKey {
    NSDictionary *value = [self td_ObjectForKey:aKey];
    if (value && [value isKindOfClass:[NSDictionary class]]) {
        return value;
    }
    return nil;
}

@end

@implementation NSMutableDictionary (TDAdd)

- (void)td_SetObjectSafe:(id)anObject forKey:(id<NSCopying>)aKey {
    if (!aKey || !anObject) {
        TDLog(@"对象 或者 key 为空");
        return;
    }
    return [self setObject:anObject forKey:aKey];
}

@end
