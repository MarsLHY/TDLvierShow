//
//  TCLiveListModel.m
//  TCLVBIMDemo
//
//  Created by annidyfeng on 16/8/3.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import "TCLiveListModel.h"


@implementation TCLiveUserInfo

- (void) encodeWithCoder: (NSCoder *)coder {
    [coder encodeObject:_nickname forKey:@"nickname" ];
    [coder encodeObject:_headpic forKey:@"headpic" ];
    [coder encodeObject:_frontcover forKey:@"frontcover" ];
    [coder encodeObject:_location forKey:@"location" ];
}

- (id) initWithCoder: (NSCoder *) coder
{
    self = [super init];
    if (self) {
        self.nickname = [coder decodeObjectForKey:@"nickname" ];
        self.headpic = [coder decodeObjectForKey:@"headpic" ];
        self.frontcover = [coder decodeObjectForKey:@"frontcover" ];
        self.location = [coder decodeObjectForKey:@"location" ];
    }
    return self;
}

@end

@implementation TCLiveInfo

- (void) encodeWithCoder: (NSCoder *)coder {
    [coder encodeObject:_userid forKey:@"userid" ];
    [coder encodeObject:_groupid forKey:@"groupid" ];
    [coder encodeObject:@(_type) forKey:@"type" ];
    [coder encodeObject:@(_viewercount) forKey:@"viewercount" ];
    [coder encodeObject:@(_likecount) forKey:@"likecount" ];
    [coder encodeObject:_title forKey:@"title" ];
    [coder encodeObject:_playurl forKey:@"playurl" ];
    [coder encodeObject:_fileid forKey:@"fileid" ];
    [coder encodeObject:_userinfo forKey:@"userinfo" ];
}

- (id) initWithCoder: (NSCoder *) coder
{
    self = [super init];
    if (self) {
        self.userid = [coder decodeObjectForKey:@"userid" ];
        self.groupid = [coder decodeObjectForKey:@"groupid" ];
        self.type = [[coder decodeObjectForKey:@"type" ] intValue];
        self.viewercount = [[coder decodeObjectForKey:@"viewercount" ] intValue];
        self.likecount = [[coder decodeObjectForKey:@"likecount" ] intValue];
        self.title = [coder decodeObjectForKey:@"title" ];
        self.playurl = [coder decodeObjectForKey:@"playurl" ];
        self.fileid = [coder decodeObjectForKey:@"fileid" ];
        self.userinfo = [coder decodeObjectForKey:@"userinfo" ];
    }
    return self;
}

@end


// -----------------------------------------------------------------------------

#import <AFNetworking.h>
#import <MJExtension/MJExtension.h>

#define pageSize 20
#define userDefaultsKey @"TCLiveListMgr"


#define QUOTE(...) @#__VA_ARGS__
//*
NSString *json = QUOTE(
                       {
                           "returnValue": 0,
                           "returnMsg": "return successfully!",
                           "returnData": {
                               "all_count": 1,
                               "pusherlist": [
                                              {
                                                  "userid" : "aaaa",
                                                  "groupid" : "bbbb",
                                                  "timestamp" : 1874483992,
                                                  "type" : 1,
                                                  "viewercount" : 1888,
                                                  "likecount" : 888,
                                                  "title" : "Testest",
                                                  "playurl" : "rtmp://live.hkstv.hk.lxdns.com/live/hks",
                                                  "userinfo" : {
                                                      "nickname": "Testest",
                                                      "userid" : "aaaa",
                                                      "groupid" : "bbbb",
                                                      "headpic" : "http://wx.qlogo.cn/mmopen/xxLzNxqMsxnlE4O0LjLaxTkiapbRU1HpVNPPvZPWb4MTicy1G1hJtEic0VGLbMFUrVA5ILoAnjQ2enNTSMYIe2hrQFkfRRfBccQ/132",
                                                      "frontcover" : "http://wx.qlogo.cn/mmopen/xxLzNxqMsxnlE4O0LjLaxTkiapbRU1HpVNPPvZPWb4MTicy1G1hJtEic0VGLbMFUrVA5ILoAnjQ2enNTSMYIe2hrQFkfRRfBccQ/0",
                                                      "location" : "深圳"
                                                  }
                                              }
                                              ]
                           }
                       }
                       );

//*/
NSString *const kTCLiveListNewDataAvailable = @"kTCLiveListNewDataAvailable";
NSString *const kTCLiveListSvrError = @"kTCLiveListSvrError";
NSString *const kTCLiveListUpdated = @"kTCLiveListUpdated";

@interface TCLiveListMgr()

@property NSMutableArray        *allLivesArray;
@property int                   totalCount;
@property int                   currentPage;
@property BOOL                  isLoading;
@property BOOL                  isVideoTypeChange;
@property VideoType             videoType;
@property AFHTTPSessionManager  *httpSession;

@end

@implementation TCLiveListMgr

- (instancetype)init {
    self = [super init];
    if (self) {
        _allLivesArray = [NSMutableArray new];
        _totalCount = 0;
        _isLoading = NO;
        _httpSession = [AFHTTPSessionManager manager];
#ifdef NDEBUG
        _httpSession.requestSerializer.timeoutInterval = 5.f;
#endif
        [_httpSession setRequestSerializer:[AFJSONRequestSerializer serializer]];
        [_httpSession setResponseSerializer:[AFJSONResponseSerializer serializer]];
        _httpSession.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/xml", @"text/plain", nil];
        
    }
    return self;
}

+ (instancetype)sharedMgr {
    static TCLiveListMgr *mgr;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (mgr == nil) {
            mgr = [TCLiveListMgr new];
        }
    });
    return mgr;
}

- (void)queryVideoList:(VideoType)videoType getType:(GetType)getType{
    _isLoading = YES;
    
    if (getType == GetType_Up || _videoType != videoType) {
        _currentPage = 0;
        [self cleanAllLives];
        _videoType = videoType;
    }
    
    [_httpSession.operationQueue cancelAllOperations];
    
    [self loadNextLives:videoType];
}

- (void)loadNextLives:(VideoType)type {
    if (_currentPage * pageSize > _totalCount) {
        _isLoading = NO;
        [self dumpLivesToArchive];
        [self postDataAvaliableNotify];
        return ;
    }
    
    _currentPage++;
    
    //flag: 1表示拉取直播列表，2表示拉取点播列表， 3表示拉取混合列表（直播+点播列表，点播最多拉取最近一周的列表）
    NSDictionary *param = @{@"Action":@"FetchList", @"flag":@(type), @"pageno":@(_currentPage), @"pagesize":@20};
    [_httpSession POST:kHttpServerAddr parameters:param progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
#if 0
        responseObject = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
#endif
        int result = [responseObject[@"returnValue"] intValue];
        if (result != 0) {
            [self postSvrErrorNotify:result reason:responseObject[@"returnMsg"]];
            return;
        }
        
        NSDictionary *returnData = responseObject[@"returnData"];
        _totalCount = [returnData[@"totalcount"] intValue];
        if (_totalCount > 0) {
            NSArray *pusher = [TCLiveInfo mj_objectArrayWithKeyValuesArray:returnData[@"pusherlist"]];
            
            @synchronized (self) {
                [_allLivesArray addObjectsFromArray:pusher];
                // 防止服务器不一致
                if (_totalCount < _allLivesArray.count) {
                    _totalCount = (int)_allLivesArray.count;
                }
            }
            
        }
        _isLoading = NO;
        [self dumpLivesToArchive];
        [self postDataAvaliableNotify];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        _isLoading = NO;
        NSLog(@"finish loading");
        [[NSNotificationCenter defaultCenter] postNotificationName:kTCLiveListSvrError object:error];
    }];
}

- (NSArray *)readLives:(NSRange)range finish:(BOOL *)finish {
    NSArray *res = nil;
    
    @synchronized (self) {
        if (range.location < _allLivesArray.count) {
            range.length = MIN(range.length, _allLivesArray.count - range.location);
            res = [_allLivesArray subarrayWithRange:range];
        }
    }
    
    if (range.location + range.length >= _totalCount) { // _totalCount = 0表示还没有拉到数据
        *finish = YES;
    } else {
        *finish = NO;
    }
    return res;
}

- (TCLiveInfo*)readLive:(int)type userId:(NSString*)userId fileId:(NSString*)fileId
{
    TCLiveInfo* info = nil;
    if (nil == userId)
        return nil;
    
    @synchronized (self) {
        for (TCLiveInfo* item in _allLivesArray)
        {
            if (0 == type)
            {
                if (type == item.type && [userId isEqualToString:item.userid])
                {
                    info = item;
                    break;
                }
                
                //直播在前，点播在后，所以如果type为直播，一旦遍历到点播，说明没取到数据，直接break
                if (0 != item.type)
                    break;
            }
            else
            {
                if (type == item.type && [userId isEqualToString:item.userid] && [fileId isEqualToString:item.fileid])
                {
                    info = item;
                    break;
                }
            }
        }
    }
    return info;
}

- (void)cleanAllLives {
    @synchronized (self) {
        [_allLivesArray removeAllObjects];
    }
}

- (void)postDataAvaliableNotify {
    [[NSNotificationCenter defaultCenter] postNotificationName:kTCLiveListNewDataAvailable object:nil];
}

- (void)postSvrErrorNotify:(int)error reason:(NSString *)msg {
    NSError *e = [NSError errorWithDomain:NSOSStatusErrorDomain code:error userInfo:@{NSLocalizedFailureReasonErrorKey:msg}];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTCLiveListSvrError object:e];
}

#pragma mark - 持久化存储
- (void)loadLivesFromArchive {
    NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
    NSData *savedArray = [currentDefaults objectForKey:userDefaultsKey];
    if (savedArray != nil)
    {
        NSArray *oldArray = [NSKeyedUnarchiver unarchiveObjectWithData:savedArray];
        if (oldArray != nil) {
            @synchronized (self) {
                _allLivesArray = [[NSMutableArray alloc] initWithArray:oldArray];
                _totalCount = (int)_allLivesArray.count;
            }
        }
    }
}

- (void)dumpLivesToArchive {
    @synchronized (self) {
        if (_allLivesArray.count > 0) {
            [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:_allLivesArray] forKey:userDefaultsKey];
        }
    }
}

- (void)update:(NSString*)userId viewerCount:(int)viewerCount likeCount:(int)likeCount
{
    if (nil == userId)
        return;
    @synchronized (self) {
        for (TCLiveInfo* info in _allLivesArray)
        {
            if (info.type == 0)
            {
                if ([userId isEqualToString:info.userid])
                {
                    info.viewercount = viewerCount;
                    info.likecount = likeCount;
                    NSDictionary* dict = @{@"userid" : userId, @"type" : @0};
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:kTCLiveListUpdated object:nil userInfo:dict];
                    });
                    return;
                }
            }
            else
            {
                return;
            }
        }
    }
}
@end

