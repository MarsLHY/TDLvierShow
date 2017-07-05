//
//  AppDelegate.m
//  TDLiveShow
//
//  Created by TD on 2017/7/5.
//  Copyright © 2017年 TD. All rights reserved.
//

#import "AppDelegate.h"
#import "TXRTMPSDK/TXLivePlayer.h"
#import "MainController.h"
#import "TDLoginViewController.h"
#import "TCLog.h"
#import "TCConstants.h"
#import <Bugly/Bugly.h>
#import "TDUserAgreementVC.h"
#import <UMSocialCore/UMSocialCore.h>

@interface AppDelegate ()
{
}
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self initCrashReport];
    
    //初始化log模块
    [TXLiveBase sharedInstance].delegate = [TCLog shareInstance];
    
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.window.backgroundColor = [UIColor whiteColor];
    
    [self enterLoginUI];
    
    //打开调试日志
    [[UMSocialManager defaultManager] openLog:YES];
    
    //设置友盟appkey
    [[UMSocialManager defaultManager] setUmSocialAppkey:@"57f214fb67e58ecb11003aea"];
    
    // 获取友盟social版本号
    NSLog(@"UMeng social version: %@", [UMSocialGlobal umSocialSDKVersion]);
    
    //设置微信的appId和appKey
    [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_WechatSession appKey:kWeiXin_Share_ID appSecret:kWeiXin_Share_Secrect redirectURL:@"http://mobile.umeng.com/social"];
    
    //设置分享到QQ互联的appId和appKey
    [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_QQ appKey:kQQZone_Share_ID  appSecret:kQQZone_Share_Secrect redirectURL:@"http://mobile.umeng.com/social"];
    
    //设置新浪的appId和appKey
    [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_Sina appKey:kSina_WeiBo_Share_ID  appSecret:kSina_WeiBo_Share_Secrect redirectURL:@"http://sns.whalecloud.com/sina2/callback"];
    
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)initCrashReport {
    NSArray* version= [TXLivePlayer getSDKVersion];
    if ([version count] >= 4) {
        //启动bugly组件，bugly组件为腾讯提供的用于crash上报和分析的开放组件，如果您不需要该组件，可以自行移除
        BuglyConfig * config = [[BuglyConfig alloc] init];
        NSString* ver = [NSString stringWithFormat:@"%@.%@.%@.%@",[version objectAtIndex:0],[version objectAtIndex:1],[version objectAtIndex:2],[version objectAtIndex:3]];
        config.version = ver;
#if DEBUG
        config.debugMode = YES;
#endif
        
        config.channel = @"xiaozhibo";
        
        [Bugly startWithAppId:BUGLY_APP_ID config:config];
        
        NSLog(@"rtmp demo init crash report");
        
    }
}

- (void)enterLoginUI {
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[TDLoginViewController alloc] init]];
    [self.window makeKeyAndVisible];
}

- (void)enterMainUI {
    if (YES == [[[NSUserDefaults standardUserDefaults] objectForKey:TDUserAgreement] boolValue]) {
        [self confirmEnterMainUI];
    }else{
        [self enterUserAgreementUI];
    }
}

- (void)confirmEnterMainUI{
    self.window.rootViewController = [[MainController alloc] init];
    [self.window makeKeyAndVisible];
}

- (void)enterUserAgreementUI{
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[TDUserAgreementVC alloc] init]];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    BOOL result = [[UMSocialManager defaultManager] handleOpenURL:url];
    if (!result) {
        
    }
    return result;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    BOOL result = [[UMSocialManager defaultManager] handleOpenURL:url];
    if (!result) {
        
    }
    return result;
}

@end
