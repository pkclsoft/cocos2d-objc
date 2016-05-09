//
//  CCTVButton.m
//
//  Created by Peter Easdown on 18/12/2015.
//

#import "CCTVButton.h"
#import "CCControlSubclass.h"
#import "cocos2d.h"

@implementation CCTVButton {
    
    BOOL _selected;
    BOOL _focused;
    
    CCNode<CCFocusableControl> *_proxy;
}

@synthesize proxy = _proxy;

- (void) cleanup {
    [self.proxy removeFromParentAndCleanup:YES];
    self.proxy = nil;
    
    [super cleanup];
}

#pragma mark - CCFocusableControl

#define FocusActionTag 3452

- (BOOL) isEnabled {
    return self.enabled;
}

- (void) setIsEnabled:(BOOL)isEnabled {
    [self setEnabled:isEnabled];
}

- (BOOL) focused  {
    return _focused;
}

- (void) setFocused:(BOOL)focused {
    _focused = focused;
    
    if (_focused == YES) {
        [self runAction:[CCActionScaleTo actionWithDuration:0.3/2.0 scale:1.5]];
    } else {
        [self runAction:[CCActionScaleTo actionWithDuration:0.3/3.0 scale:1.0]];
    }
}

- (BOOL) wantsAngleOfTouch {
    return NO;
}

- (void) setWantsAngleOfTouch:(BOOL)wantsAngleOfTouch {
    // do nothing
}

- (BOOL) wantsControlOfTouch {
    return NO;
}

- (void) resetFocus {
    [self setFocused:NO];
}

- (void) setAngleOfTouch:(float)angleInDegrees withRadius:(float)radius firstTime:(BOOL)firstAngle lastTime:(BOOL)lastAngle {
    
}

- (void) activate {
    [super triggerAction];
}

@end
