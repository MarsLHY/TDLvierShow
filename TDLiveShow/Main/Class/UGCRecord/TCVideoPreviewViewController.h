#import "TCLiveListModel.h"
#import <UIKit/UIKit.h>
#import <TXRTMPSDK/TXUGCRecordTypeDef.h>

#define kRecordType_Camera 0
#define kRecordType_Play 1

/**
 *  短视频预览VC
 */
@interface TCVideoPreviewViewController : UIViewController
-(instancetype)initWith:(NSInteger)recordType  coverImage:(UIImage*)coverImage RecordResult:(TXRecordResult *)recordResult TCLiveInfo:(TCLiveInfo *)liveInfo;
@end
