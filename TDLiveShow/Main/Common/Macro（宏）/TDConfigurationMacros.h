
#ifndef TDConfigurationMacros_h
#define TDConfigurationMacros_h

//是否开启TDLog ，如果不开启，直接注释掉就可以了
#define Is_Strat_Log

//是否开启服务器选择功能
//#define Is_Open_Host_Choose


//1:测试服务器  2:19服务器 3:beta服务器  4：线上服务器
#define TDDomainType 1

#if TDDomainType == 3
//Beta版
#define Is_Beta_Version 1
#else
//不是Bete版
#define Is_Beta_Version 0
#endif

#pragma mark- 具体实现

//输出宏定义具体实现
#ifdef Is_Strat_Log

#define TDLog( s, ... ) NSLog( @"< 输出位置:%@:(第%d行) > 输出信息：%@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )

#else

#define TDLog( s, ... )

#endif


/*********重要信息的key*********/
typedef NS_ENUM(NSUInteger, Address_Host_Type) {
    Address_Host_110_Server = 0,
    Address_Host_19_Server = 1,
    Address_Host_Online_Server = 2,
    Address_Host_106_Server = 3,
    Address_Host_Custom_server = 4,
};

#endif /* TDConfigurationMacros_h */
