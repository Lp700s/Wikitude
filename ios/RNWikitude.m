#import "RNWikitude.h"
#import <React/RCTEventDispatcher.h>
#import <React/RCTView.h>
#import <React/UIView+React.h>
#import <WikitudeSDK/WikitudeSDK.h>

@implementation RNWikitude {
    // Internal
    RCTEventDispatcher *_eventDispatcher;
    UIButton *_clearButton;
    NSString *_architectWorldURL;
    WTArchitectView *_architectView;
    WTNavigation  *_architectWorldNavigation;
    NSString *_licenseKey;
}
- (void)dealloc
{
    /* Remove this view controller from the default Notification Center so that it can be released properly */
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
#pragma mark - UIViewHierarchy methods
- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
    if ((self = [super init])) {
        _eventDispatcher = eventDispatcher;
        [self initView];
    }

    return self;
}
-(void) initView
{
    NSError *deviceSupportError = nil;
    if ( [WTArchitectView isDeviceSupportedForRequiredFeatures:WTFeature_ImageTracking error:&deviceSupportError] ) {

        if (_architectWorldURL != nil && _licenseKey != nil) {

            dispatch_async(dispatch_get_main_queue(), ^{

                if (_architectView != nil) {
                    _architectView = nil;
                }

                /* Standard WTArchitectView object creation and initial configuration */
                _architectView = [[WTArchitectView alloc] init];
                _architectView.delegate = self;
                _architectView.debugDelegate = self;
                [_architectView setLicenseKey:_licenseKey];
                _architectWorldNavigation = [_architectView loadArchitectWorldFromURL:[NSURL URLWithString:[_architectWorldURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];

                [self addSubview:_architectView];
                _architectView.translatesAutoresizingMaskIntoConstraints = NO;
                NSDictionary *views = NSDictionaryOfVariableBindings(_architectView);
                [self addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"|[_architectView]|" options:0 metrics:nil views:views] ];
                [self addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_architectView]|" options:0 metrics:nil views:views] ];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveApplicationWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveApplicationDidBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
            });
        }

    }
    else {
        NSLog(@"This device is not supported. Show either an alert or use this class method even before presenting the view controller that manages the WTArchitectView. Error: %@", [deviceSupportError localizedDescription]);

    }

}
/* Convenience methods to manage WTArchitectView rendering. */
- (void)startWikitudeSDKRendering
{
    /* To check if the WTArchitectView is currently rendering, the isRunning property can be used */
    if ( ![_architectView isRunning] ) {

        /* To start WTArchitectView rendering and control the startup phase, the -start:completion method can be used */
        [_architectView start:^(WTStartupConfiguration *configuration) {

            /* Use the configuration object to take control about the WTArchitectView startup phase */
            /* You can e.g. start with an active front camera instead of the default back camera */

            // configuration.captureDevicePosition = AVCaptureDevicePositionFront;

        } completion:^(BOOL isRunning, NSError *error) {

            /* The completion block is called right after the internal start method returns. NOTE: In case some requirements are not given, the WTArchitectView might not be started and returns NO for isRunning. To determine what caused the problem, the localized error description can be used. */
            if ( !isRunning ) {
                NSLog(@"WTArchitectView could not be started. Reason: %@", [error localizedDescription]);
            }
        }];
    }else{
        [_architectView reloadArchitectWorld];
    }
}
- (void)stopWikitudeSDKRendering
{
    /* The stop method is blocking until the rendering and camera access is stopped */
    if ( [_architectView isRunning] ) {
        [_architectView stop];
    }
}
/* The WTArchitectView provides two delegates to interact with. */
#pragma mark - Delegation
/* The standard delegate can be used to get information about: * The Architect World loading progress * The method callback for AR.platform.sendJSONObject caught by -architectView:receivedJSONObject: * Managing view capturing * Customizing view controller presentation that is triggered from the WTArchitectView */
#pragma mark WTArchitectViewDelegate
- (void)architectView:(WTArchitectView *)architectView didFinishLoadArchitectWorldNavigation:(WTNavigation *)navigation
{
    /* Architect World did finish loading */
}
- (void)architectView:(WTArchitectView *)architectView didFailToLoadArchitectWorldNavigation:(WTNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"Architect World from URL '%@' could not be loaded. Reason: %@", navigation.originalURL, [error localizedDescription]);
}
/* The debug delegate can be used to respond to internal issues, e.g. the user declined camera or GPS access. NOTE: The debug delegate method -architectView:didEncounterInternalWarning is currently not used. */
#pragma mark WTArchitectViewDebugDelegate
- (void)architectView:(WTArchitectView *)architectView didEncounterInternalWarning:(WTWarning *)warning
{
    /* Intentionally Left Blank */
}
- (void)architectView:(WTArchitectView *)architectView didEncounterInternalError:(NSError *)error
{
    NSLog(@"WTArchitectView encountered an internal error '%@'", [error localizedDescription]);
}
- (void)architectView:(WTArchitectView *)architectView receivedJSONObject:(NSDictionary *)jsonObject
{
    NSLog(@"receivedJSONObject %@", [jsonObject objectForKey:@"type"]);
    
    if ([@[
           @"TARGET_SCANNED",
           @"TARGET_LOST",
           @"PROJECT_LOADED"
       ] containsObject:[jsonObject objectForKey:@"type"]]) {
        _onWikitudeEvent(jsonObject);
    }
}
#pragma mark - Notifications
/* UIApplication specific notifications are used to pause/resume the architect view rendering */
- (void)didReceiveApplicationWillResignActiveNotification:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        /* Standard WTArchitectView rendering suspension when the application resignes active */
        [self stopWikitudeSDKRendering];
    });
}
- (void)didReceiveApplicationDidBecomeActiveNotification:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{

        /* When the application starts for the first time, several UIAlert's might be shown to ask the user for camera and/or GPS access. Because the WTArchitectView is paused when the application resigns active (See line 86), also Architect JavaScript evaluation is interrupted. To resume properly from the inactive state, the Architect World has to be reloaded if and only if an active Architect World load request was active at the time the application resigned active. This loading state/interruption can be detected using the navigation object that was returned from the -loadArchitectWorldFromURL:withRequiredFeatures method. */
        if ( _architectWorldNavigation.wasInterrupted )
        {
            [_architectView reloadArchitectWorld];
        }

        /* Standard WTArchitectView rendering resuming after the application becomes active again */
        if ( _licenseKey != nil) {
            [self startWikitudeSDKRendering];
        }
    });
}
- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
- (void)removeFromSuperview
{
    _eventDispatcher = nil;
    [super removeFromSuperview];
}
-(void)reloadView
{
    [self initView];
}
- (void)startRendering
{
    [self startWikitudeSDKRendering];
}
- (void)setArchitectWorldURL:(NSString *) architectWorldURL
{
    NSLog(@"stringByAddingPercentEscapesUsingEncoding self.architectWorldURL is: %@", [NSURL URLWithString:[architectWorldURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]);
    _architectWorldURL = architectWorldURL;
    [self initView];
}
- (void)setLicenseKey:(NSString *) licenseKey
{
    _licenseKey = licenseKey;
    [self initView];
}
@end
