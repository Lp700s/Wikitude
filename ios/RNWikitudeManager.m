#import "RNWikitudeManager.h"
#import "RNWikitude.h"
#import <React/RCTBridgeModule.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTLog.h>
#import <React/RCTView.h>
#import <React/UIView+React.h>
#import <WikitudeSDK/WikitudeSDK.h>
#import <WikitudeSDK/WTArchitectViewDebugDelegate.h>
@implementation RNWikitudeManager
RCT_EXPORT_MODULE();
#pragma mark - Properties
RCT_EXPORT_VIEW_PROPERTY(onWikitudeEvent, RCTBubblingEventBlock)
RCT_CUSTOM_VIEW_PROPERTY(licenseKey, NSString, RNWikitude){
    [view setLicenseKey:json ? [RCTConvert NSString:json] : @""];
}
RCT_CUSTOM_VIEW_PROPERTY(architectWorldURL, NSString, RNWikitude)
{
    [view setArchitectWorldURL:json ? [RCTConvert NSString:json] : @""];
}
RCT_CUSTOM_VIEW_PROPERTY(rendering, NSString, RNWikitude){
    NSString *rendering = json ? [RCTConvert NSString:json] : @"";
    if ([rendering isEqualToString:@"start"]) {
        // Start Rendering
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.rnWikitude startRendering];
        });
    } else if ([rendering isEqualToString:@"stop"]) {
        // Stop Rendering
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.rnWikitude stopWikitudeSDKRendering];
        });
    }
}
RCT_CUSTOM_VIEW_PROPERTY(unload, NSString, RNWikitude){
    NSString *unload = json ? [RCTConvert NSString:json] : @"";
    if ([unload isEqualToString:@"unload"]) {
        // Stop Rendering
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.rnWikitude stopWikitudeSDKRendering];
            self.rnWikitude = nil;
        });
    }
}
#pragma mark - Lifecycle
- (instancetype)init
{

    if ((self = [super init])) {
        self.rnWikitude = nil;
    }

    return self;
}
- (UIView *)view
{
    if (!self.rnWikitude) {
        self.rnWikitude = [[RNWikitude alloc] initWithEventDispatcher:self.bridge.eventDispatcher];
    }

    return self.rnWikitude;
}
#pragma mark - Event types
- (NSArray *)customDirectEventTypes
{
    return @[
             @"onReset",
             ];
}
RCT_EXPORT_METHOD(unload)
{
    [self.rnWikitude stopWikitudeSDKRendering];
    self.rnWikitude = nil;
}
- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
@end
