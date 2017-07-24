//
//  MD5And3DES.h
//  TuanDaiLive
//
//  Created by TD on 2017/5/23.
//  Copyright © 2017年 tuandai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MD5And3DES : NSObject
//MD5
+ (NSString *) md5:(NSString *) input;

//3DES
/**字符串加密 */
+ (NSString *)doEncryptStr:(NSString *)originalStr;
/**字符串解密 */
+ (NSString*)doDecEncryptStr:(NSString *)encryptStr;
/**十六进制解密 */
+ (NSString *)doEncryptHex:(NSString *)originalStr;
/**十六进制加密 */
+ (NSString*)doDecEncryptHex:(NSString *)encryptStr;
@end
