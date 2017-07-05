//
//  TXVideoLoadingController.m
//  TCLVBIMDemo
//
//  Created by annidyfeng on 2017/4/17.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "TXVideoLoadingController.h"
#import <QBImagePickerController/QBImagePickerController.h>
#import "TCVideoEditViewController.h"
#import "TCVideoJoinViewController.h"
#import <Photos/Photos.h>

@interface TXVideoLoadingController ()
@property IBOutlet UIImageView *loadingImageView;
@property AVAssetExportSession *exportSession;
@property NSTimer *timer;
@property NSMutableArray *localPaths;
@property NSArray     *videosAssets;
@property NSUInteger  exportIndex;
@property AVMutableComposition *mutableComposition;
@property AVMutableVideoComposition *mutableVideoComposition;
@end

@implementation TXVideoLoadingController
{

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)exportAssetList:(NSArray *)videosAssets
{
    _videosAssets = videosAssets;
    _exportIndex = 0;
    _localPaths = [NSMutableArray new];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
    
    [self exportAssetInternal];
}

- (void)exportAssetInternal
{
    if (_exportIndex == _videosAssets.count) {
        //
        [self.timer invalidate], self.timer = nil;
        
        if (!self.composeMode) {
            TCVideoEditViewController *vc = [TCVideoEditViewController new];
            vc.videoPath = _localPaths[0];
            [self.navigationController pushViewController:vc animated:YES];
            return;
        } else {
            TCVideoJoinViewController *vc = [TCVideoJoinViewController new];
            vc.videoList = _localPaths;
            [self.navigationController pushViewController:vc animated:YES];
            return;
        }
    }
    
    self.mutableComposition = nil;
    self.mutableVideoComposition = nil;
    
    __weak typeof(self) weakSelf = self;
    PHAsset *expAsset = _videosAssets[_exportIndex];
    [[PHImageManager defaultManager] requestAVAssetForVideo:expAsset options:nil resultHandler:^(AVAsset * _Nullable avAsset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        LBVideoOrientation or = avAsset.videoOrientation;
        if (or == LBVideoOrientationUp || or == LBVideoOrientationDown) {
            CGFloat angle = 0;
            if (or == LBVideoOrientationUp)   angle = 90.0;
            if (or == LBVideoOrientationDown) angle = -90.0;
            [self performWithAsset:avAsset rotate:angle];
            _exportSession = [[AVAssetExportSession alloc] initWithAsset:self.mutableComposition presetName:AVAssetExportPresetHighestQuality];
            _exportSession.videoComposition = self.mutableVideoComposition;
        } else {
            _exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetHighestQuality];
        }
 
        
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString* videoPath = [documentsDirectory stringByAppendingPathComponent:[expAsset orignalFilename]];
        NSFileManager *manager = [NSFileManager defaultManager];

        NSError *error;
        if ([manager fileExistsAtPath:videoPath]) {
            BOOL success = [manager removeItemAtPath:videoPath error:&error];
            if (success) {
                NSLog(@"Already exist. Removed!");
            }
        }
        [self.localPaths addObject:videoPath];
        
        NSURL *outputURL = [NSURL fileURLWithPath:videoPath];
        _exportSession.outputURL = outputURL;
        _exportSession.outputFileType = AVFileTypeMPEG4;
        [_exportSession exportAsynchronouslyWithCompletionHandler:^{
                if (_exportSession.status == AVAssetExportSessionStatusFailed) {
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        [weakSelf exportAssetError];
                    });

                } else if(_exportSession.status == AVAssetExportSessionStatusCompleted){
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        _exportIndex++;
                        [weakSelf exportAssetInternal];
                    });
                }
        }];
    }];
}

- (void)exportAssetError
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"视频导出失败" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"好" style:0 handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)updateProgress
{
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat progress = self.exportSession.progress;
        if (self.exportSession.status == AVAssetExportSessionStatusFailed ||
            self.exportSession.status == AVAssetExportSessionStatusCompleted) {
            progress = 1;
        }
        CGFloat allp = (progress + _exportIndex)/_videosAssets.count;
        self.loadingImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"video_record_share_loading_%d", (int)(allp * 8)]];
    });
}

#define degreesToRadians( degrees ) ( ( degrees ) / 180.0 * M_PI )



- (void)performWithAsset:(AVAsset*)asset rotate:(CGFloat)angle
{
    AVMutableVideoCompositionInstruction *instruction = nil;
    AVMutableVideoCompositionLayerInstruction *layerInstruction = nil;
    CGAffineTransform t1;
    CGAffineTransform t2;
    
    AVAssetTrack *assetVideoTrack = nil;
    AVAssetTrack *assetAudioTrack = nil;
    // Check if the asset contains video and audio tracks
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
    }
    if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        assetAudioTrack = [asset tracksWithMediaType:AVMediaTypeAudio][0];
    }
    
    CMTime insertionPoint = kCMTimeZero;
    NSError *error = nil;
    
    
    // Step 1
    // Create a composition with the given asset and insert audio and video tracks into it from the asset
    if (!self.mutableComposition) {
        
        // Check whether a composition has already been created, i.e, some other tool has already been applied
        // Create a new composition
        self.mutableComposition = [AVMutableComposition composition];
        
        // Insert the video and audio tracks from AVAsset
        if (assetVideoTrack != nil) {
            AVMutableCompositionTrack *compositionVideoTrack = [self.mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetVideoTrack atTime:insertionPoint error:&error];
        }
        if (assetAudioTrack != nil) {
            AVMutableCompositionTrack *compositionAudioTrack = [self.mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetAudioTrack atTime:insertionPoint error:&error];
        }
        
    }
    
    
    // Step 2
    // Translate the composition to compensate the movement caused by rotation (since rotation would cause it to move out of frame)
    if (angle == 90)
    {
        t1 = CGAffineTransformMakeTranslation(assetVideoTrack.naturalSize.height, 0.0);
    }else if (angle == -90){
        t1 = CGAffineTransformMakeTranslation(0.0, assetVideoTrack.naturalSize.width);
    } else {
        return;
    }
    // Rotate transformation
    t2 = CGAffineTransformRotate(t1, degreesToRadians(angle));
    
    
    // Step 3
    // Set the appropriate render sizes and rotational transforms
    if (!self.mutableVideoComposition) {
        
        // Create a new video composition
        self.mutableVideoComposition = [AVMutableVideoComposition videoComposition];
        self.mutableVideoComposition.renderSize = CGSizeMake(assetVideoTrack.naturalSize.height,assetVideoTrack.naturalSize.width);
        self.mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
        
        // The rotate transform is set on a layer instruction
        instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [self.mutableComposition duration]);
        layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:(self.mutableComposition.tracks)[0]];
        [layerInstruction setTransform:t2 atTime:kCMTimeZero];
        
    } else {
        
        self.mutableVideoComposition.renderSize = CGSizeMake(self.mutableVideoComposition.renderSize.height, self.mutableVideoComposition.renderSize.width);
        
        // Extract the existing layer instruction on the mutableVideoComposition
        instruction = (self.mutableVideoComposition.instructions)[0];
        layerInstruction = (instruction.layerInstructions)[0];
        
        // Check if a transform already exists on this layer instruction, this is done to add the current transform on top of previous edits
        CGAffineTransform existingTransform;
        
        if (![layerInstruction getTransformRampForTime:[self.mutableComposition duration] startTransform:&existingTransform endTransform:NULL timeRange:NULL]) {
            [layerInstruction setTransform:t2 atTime:kCMTimeZero];
        } else {
            // Note: the point of origin for rotation is the upper left corner of the composition, t3 is to compensate for origin
            CGAffineTransform t3 = CGAffineTransformMakeTranslation(-1*assetVideoTrack.naturalSize.height/2, 0.0);
            CGAffineTransform newTransform = CGAffineTransformConcat(existingTransform, CGAffineTransformConcat(t2, t3));
            [layerInstruction setTransform:newTransform atTime:kCMTimeZero];
        }
        
    }
    
    
    // Step 4
    // Add the transform instructions to the video composition
    instruction.layerInstructions = @[layerInstruction];
    self.mutableVideoComposition.instructions = @[instruction];
    
    
    // Step 5
    // Notify AVSEViewController about rotation operation completion
//    [[NSNotificationCenter defaultCenter] postNotificationName:AVSEEditCommandCompletionNotification object:self];
}

@end


@implementation PHAsset (My)

- (NSString *)orignalFilename {
    NSString *filename;
    if ([[PHAssetResource class] instancesRespondToSelector:@selector(assetResourcesForAsset:)]) {
        NSArray *resources = [PHAssetResource assetResourcesForAsset:self];
        PHAssetResource *resource = resources.firstObject;
        if (resources) {
            filename = resource.originalFilename;
        }
    }
    if (filename == nil) {
        filename = [self valueForKey:@"filename"];
        if (filename == nil ||
            ![filename isKindOfClass:[NSString class]]) {
            filename = [NSString stringWithFormat:@"temp%ld", time(NULL)];
        }
    }
    
    return filename;
}

@end


static inline CGFloat RadiansToDegrees(CGFloat radians) {
    return radians * 180 / M_PI;
};

@implementation AVAsset (My)
@dynamic videoOrientation;

- (LBVideoOrientation)videoOrientation
{
    NSArray *videoTracks = [self tracksWithMediaType:AVMediaTypeVideo];
    if ([videoTracks count] == 0) {
        return LBVideoOrientationNotFound;
    }
    
    AVAssetTrack* videoTrack    = [videoTracks objectAtIndex:0];
    CGAffineTransform txf       = [videoTrack preferredTransform];
    CGFloat videoAngleInDegree  = RadiansToDegrees(atan2(txf.b, txf.a));
    
    LBVideoOrientation orientation = 0;
    switch ((int)videoAngleInDegree) {
        case 0:
            orientation = LBVideoOrientationRight;
            break;
        case 90:
            orientation = LBVideoOrientationUp;
            break;
        case 180:
            orientation = LBVideoOrientationLeft;
            break;
        case -90:
            orientation	= LBVideoOrientationDown;
            break;
        default:
            orientation = LBVideoOrientationNotFound;
            break;
    }
    
    return orientation;
}

@end
