#import <UIKit/UIKit.h>
#import <React/RCTComponent.h>
#import <WikitudeSDK/WikitudeSDK.h>

@class RCTEventDispatcher;

@interface RNWikitude : UIView <WTArchitectViewDelegate, WTArchitectViewDebugDelegate>

@property (nonatomic, copy) RCTBubblingEventBlock onWikitudeEvent;

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispather NS_DESIGNATED_INITIALIZER;
- (void)setArchitectWorldURL:(NSString *) architectWorldURL;
- (void)setLicenseKey:(NSString *) licenseKey;
- (void)startRendering;
- (void)stopWikitudeSDKRendering;
@end
