#import <UIKit/UIKit.h>
#import "TCMsgHandler.h"

#define kMaxRecordDuration 60.f

@protocol TCPlayUGCDecorateViewDelegate <NSObject>
- (void)closeRecord;
- (void)recordVideo:(BOOL)isStart;
- (void)resetRecord;
@end

/**
 *  观众端短视频录制
 */
@interface TCPlayUGCDecorateView : UIView<AVIMMsgListener>

@property(nonatomic,weak) id<TCPlayUGCDecorateViewDelegate>delegate;

- (instancetype)initWithFrame:(CGRect)frame;

- (void) setVideoRecordProgress:(float) progress;

@end
