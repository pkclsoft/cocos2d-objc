//
//  CCFocusableControlProxy.m
//
//  Created by Peter Easdown on 18/12/2015.
//

#import "CCFocusableControlProxy.h"
#import "CCControlSubclass.h"

@implementation CCFocusableControlProxy

- (id) initWithControl:(CCControl<CCFocusableControl, CCControlProxy>*)control {
    self = [super init];
    
    if (self != nil) {
        self.contentSizeType = CCSizeTypePoints;
        self.contentSize = control.contentSizeInPoints;
        self.positionType = CCPositionTypePoints;
        self.control = control;
        self.control.proxy = self;
    }
    
    return self;
}

+ (CCFocusableControlProxy*) proxyForControl:(CCControl<CCFocusableControl, CCControlProxy>*)control {
    return [[CCFocusableControlProxy alloc] initWithControl:control];
}

- (void) cleanup {
    self.control.proxy = nil;
    self.control = nil;
    
    [super cleanup];
}

- (CGPoint) position {
    return [self positionInPoints];
}

- (CGPoint) positionInPoints {
    return [self.control.parent convertToWorldSpace:self.control.positionInPoints];
}

- (CCAction*) runAction:(CCAction *)action {
    return [self.control runAction:action];
}

- (void) stopAction:(CCAction *)action {
    [self.control stopAction:action];
}

- (void) stopActionByTag:(NSInteger)tag {
    [self.control stopActionByTag:tag];
}

- (void) stopAllActions {
    [self.control stopAllActions];
}

#pragma mark - CCFocusableControl

- (BOOL) isEnabled {
    return self.control.isEnabled;
}

- (void) setIsEnabled:(BOOL)isEnabled {
    [self.control setEnabled:isEnabled];
}

- (BOOL) focused  {
    return self.control.focused;
}

- (void) setFocused:(BOOL)focused {
    [self.control setFocused:focused];
}

- (BOOL) wantsAngleOfTouch {
    return self.control.wantsAngleOfTouch;
}

- (void) setWantsAngleOfTouch:(BOOL)wantsAngleOfTouch {
    [self.control setWantsAngleOfTouch:wantsAngleOfTouch];
}

- (BOOL) wantsControlOfTouch {
    return self.control.wantsControlOfTouch;
}

- (void) resetFocus {
    [self.control resetFocus];
}

- (void) setAngleOfTouch:(float)angleInDegrees withRadius:(float)radius firstTime:(BOOL)firstAngle lastTime:(BOOL)lastAngle {
    [self.control setAngleOfTouch:angleInDegrees withRadius:radius firstTime:firstAngle lastTime:lastAngle];
}

- (void) activate {
    [self.control activate];
}

- (void) playerDidPressPlayPause {
    if ([self.control respondsToSelector:@selector(playerDidPressPlayPause)] == YES) {
        [self.control playerDidPressPlayPause];
    }
}

@end
