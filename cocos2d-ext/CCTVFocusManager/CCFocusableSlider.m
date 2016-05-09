//
//  CCFocusableSlider.m
//
//  Created by Peter Easdown on 4/03/2016.
//

#import "CCFocusableSlider.h"

@interface CCFocusableSlider ()

@property (nonatomic) BOOL activated;

@end

@interface CCSlider (private)

/* These methods are privately declared in the super class.  Need access to them here. */
- (void) inputEnteredWithWorlPos:(CGPoint)worldLocation;

- (void) inputUpInside;

- (void) inputUpOutside;

- (void) inputDraggedWithPos:(CGPoint)dragPos;

@end

@implementation CCFocusableSlider {
    
    BOOL _focused;
    
    CCNode<CCFocusableControl> *_proxy;
}

@synthesize proxy = _proxy;

/**
 *  Like anything else, if the item is enabled, this should be YES.
 */
- (BOOL) isEnabled {
    return self.enabled;
}

- (void) setIsEnabled:(BOOL)isEnabled {
    self.enabled = isEnabled;
}

/**
 *  Indicates whether the item is focused or not.  Override the setter if you want to implement a special animation or
 *  visual indication of selection to the user.  If you don't it won't be obvious that the item is selected.
 */
- (BOOL) focused {
    return self.focused;
}

- (void) setFocused:(BOOL)focused {
    _focused = focused;
    
    if (_focused == YES) {
        [self runAction:[CCActionScaleTo actionWithDuration:0.3 scale:1.5]];
    } else {
        [self runAction:[CCActionScaleTo actionWithDuration:0.3 scale:1.0]];
    }
}

/**
 *  Some menu items may be interested in knowing what the user is doing when they have focus.  For example, a slider, or
 *  a potentiometer might want to be able to respond to the user panning either for visual effect or for the purpose of
 *  changing internal state.
 *
 *  Set this to YES if the item is such a beast, and CCTVMenu will pass panning events through to the menu item whenever
 *  the method [wantsControlOfTouch:] returns YES.
 */
- (BOOL) wantsAngleOfTouch {
    return self.activated;
}

- (void) setWantsAngleOfTouch:(BOOL)wantsAngleOfTouch {
    
}

/**
 *  As per the property wantsAngleOfTouch, this method should return YES if the menu item wants control over the users
 *  panning.  This basically allows an item to wrestle control from the CCTVMenu when it needs to so that the CCTVMenu's
 *  handling of panning to another menu item doesn't interact with the items internal handler.
 *
 *  An example use of this is a potentiometer, used to set the volume of music.  The user would pan to focus the potentiometer
 *  click to activate it (which causes this method to return YES) and then pan to adjust the value of the volume.  Clicking
 *  then deactivates and returns panning control back to the CCTVMenu instance.
 */
- (BOOL) wantsControlOfTouch {
    return self.activated;
}

/**
 *  This method is for those times when you have an animation to highlight focus of an item and you want to restart it without
 *  removing focus altogether.
 */
- (void) resetFocus {
    // do nothing
    [self setFocused:NO];
    self.activated = NO;
}

// Converts an angle in the world where 0 is north in a clockwise direction to a world
// where 0 is east in an anticlockwise direction.
//
- (float) angleFromDegrees:(float)deg {
    return fmodf((450.0f - deg), 360.0);
}

- (CGPoint) pointOnCircleWithCentre:(CGPoint)centerPt andRadius:(float)radius atDegrees:(float)degrees {
    float x = radius + cosf (CC_DEGREES_TO_RADIANS([self angleFromDegrees:degrees])) * radius;
    float y = radius + sinf (CC_DEGREES_TO_RADIANS([self angleFromDegrees:degrees])) * radius;
    return ccpAdd(centerPt, ccpSub(CGPointMake(x, y), CGPointMake(radius, radius)));
}

/**
 *  The angle of touch is an angle in degrees (where 0 is north, moving CW) where the angle represents the direction the users
 *  touch on the remote in relation to the start of a pan gesture.  The position of touch is irrelevant as the remote doesn't
 *  have a meaningful coordinate system.  By using this angle, the menu item can then assume that the touch is inside its
 *  frame (bacause it has focus), and it can then apply actions based on the angle.  For example, you can calculate a point on
 *  a circle at a radius from the center of the menu item at the specified angle to indicate a relative position of touch
 *  so that the item can behave as if it would normally on iOS.
 *
 *  @param angleInDegrees is the angle
 *  @param firstAngle is YES if this is the first touch in a pan gesture.
 *  @param lastAngle is YES if this is the last touch in a pan gesture.
 */
- (void) setAngleOfTouch:(float)angleInDegrees withRadius:(float)radius firstTime:(BOOL)firstAngle lastTime:(BOOL)lastAngle {
    if (firstAngle == YES) {
        // This is the first call, so tell the super that the user has just touched the handle.
        //
        CGPoint touchPoint = [self convertToWorldSpace:CGPointMake(self.contentSizeInPoints.width/2.0, self.contentSizeInPoints.height/2.0)];
        [self inputEnteredWithWorlPos:touchPoint];
        CCLOG(@"handle.position: %@", NSStringFromCGPoint(self.handle.position));
        CCLOG(@"self.centrePosition: %@", NSStringFromCGPoint(CGPointMake(self.contentSizeInPoints.width/2.0, self.contentSizeInPoints.height/2.0)));
    } else if (lastAngle == YES) {
        // This is the last call, so end the input.
        //
    } else {
        // The user is still dragging.
        //
        CCLOG(@"setAngleOfTouch:%2.2f withRadius:%2.2f", angleInDegrees, radius);
        CGPoint touchPos = [self pointOnCircleWithCentre:CGPointMake(self.contentSizeInPoints.width/2.0, self.contentSizeInPoints.height/2.0)
                                               andRadius:(radius / 960.0) * (self.background.contentSizeInPoints.width/2.0) atDegrees:angleInDegrees];
        [self inputDraggedWithPos:touchPos];
    }
}

/**
 *  Activates the item, just like any other menu item.  This was included to ensure that classes that <em>don't</em> subclass
 *  CCMenuItem support "activation" via a click.
 */
- (void) activate {
    if (_activated == NO) {
        _activated = YES;
        self.highlighted = YES;
    } else {
        _activated = NO;
        self.highlighted = NO;
        [self inputUpInside];
    }
}

/**
 *  Override so that the touch point doesn't have to be within the handle.
 */
- (void) inputEnteredWithWorlPos:(CGPoint)worldLocation
{
    // Touch down in slider handle
    _draggingHandle = YES;
    self.highlighted = YES;
    _handleStartPos = self.handle.position;
    _dragStartPos = [self convertToNodeSpace:worldLocation];
    _dragStartValue = self.sliderValue;
}

@end
