#ifndef __TCLinkMicPlayItem_h__
#define __TCLinkMicPlayItem_h__

#import <UIKit/UIKit.h>
#import "TXRTMPSDK/TXLivePlayer.h"
#import <Foundation/Foundation.h>

@interface TCLinkMicSmallPlayer: NSObject

-(void)emptyPlayInfo;
-(void)startLoading;
-(void)stopLoading;
-(void)startPlay:(NSString*)playUrl;
-(void)stopPlay;
-(void)showLogView:(BOOL)hidden;
-(void)freshStatusMsg:(NSDictionary*)param;
-(void)appendEventMsg:(int)event andParam:(NSDictionary*)param;

@property (nonatomic, assign) BOOL                      pending;
@property (nonatomic, strong) NSString*                 userID;
@property (nonatomic, strong) NSString*                 playUrl;
@property (nonatomic, retain) TCLivePlayListenerImpl*   livePlayListener;
@property (nonatomic, retain) TXLivePlayer *            livePlayer;
@property (nonatomic, strong) UIView*                   videoView;
@property (nonatomic, strong) UIView*                   logView;
@property (nonatomic, strong) UIButton*                 btnKickout;
@end



#endif
