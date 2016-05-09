//
//  CCFocusableTextField.m
//
//  Created by Peter Easdown on 18/11/2015.
//
//  FIXME: NOTE THAT THIS CLASS WORKS, BUT ONLY 90%.  I've been unable to get proper control of focus
//  for text fields.
//

#import "CCFocusableTextField.h"

@implementation CCFocusableTextField {
    
    CCNode<CCFocusableControl> *_proxy;
}

@synthesize proxy = _proxy;

/**
 *  Like anything else, if the item is enabled, this should be YES.
 */
- (BOOL) isEnabled {
    return self.textField.isUserInteractionEnabled;
}

- (void) setIsEnabled:(BOOL)isEnabled {
    self.textField.userInteractionEnabled = isEnabled;
}

/**
 *  Indicates whether the item is focused or not.  Override the setter if you want to implement a special animation or
 *  visual indication of selection to the user.  If you don't it won't be obvious that the item is selected.
 */
- (BOOL) focused {
    return self.textField.userInteractionEnabled && self.textField.isFocused;
}

- (void) setFocused:(BOOL)focused {
    // Apple doesn't allow us to directly control focus (for good reasons in a full UIKit app), so we have to be a little tricky.  By changing
    // userInteractionEnabled we should be able to control whether UIKit allows an item to be focused or not.  So on a scene with only one UIKit
    // view, we can effectively move focus to the view by enabling it, and remove focus by disabling it.
    //
    // This shoud have worked, but it doesn't.  I ended up having to use visible to hide the control and use a label to represent the
    // unfocused text field.
    //
    self.visible = focused;
    [self.textField setSelected:focused];
    [self.textField updateFocusIfNeeded];
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
    return NO;
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
    return NO;
}

/**
 *  This method is for those times when you have an animation to highlight focus of an item and you want to restart it without
 *  removing focus altogether.
 */
- (void) resetFocus {
    // do nothing
    [self setFocused:NO];
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
    // do nothing
}

/**
 *  Activates the item, just like any other menu item.  This was included to ensure that classes that <em>don't</em> subclass
 *  CCMenuItem support "activation" via a click.
 */
-(void) activate {
    // do nothing
}

@end
