//
//  CCFocusableControl.h
//
//  Created by Peter Easdown on 4/12/2015.
//
//

#import <Foundation/Foundation.h>
#import "CCControl.h"
/**
 *  This protocol defines all of the properties and actions for a "focusable" control.  Typically, it will be
 *  implemented by a subclass of CCControl but that isn't mandatory as CCTVFocusManager doesn't require that.
 */
@protocol CCFocusableControl <NSObject>

/**
 *  Like anything else, if the control is enabled, this should be YES.
 */
@property (nonatomic) BOOL isEnabled;

/**
 *  Indicates whether the control is focused or not.  Override the setter if you want to implement a special animation or
 *  visual indication of selection to the user.  If you don't it won't be obvious that the control is selected.
 */
@property (nonatomic) BOOL focused;

/**
 *  Some controls may be interested in knowing what the user is doing when they have focus.  For example, a slider, or
 *  a potentiometer might want to be able to respond to the user panning either for visual effect or for the purpose of
 *  changing internal state.
 *
 *  Set this to YES if the control is such a beast, and CCTVFocusManager will pass panning events through to the control whenever
 *  the method [wantsControlOfTouch:] returns YES.
 */
@property (nonatomic) BOOL wantsAngleOfTouch;

/**
 *  As per the property wantsAngleOfTouch, this method should return YES if the control wants control over the users
 *  panning.  This basically allows an control to wrestle control from the CCTVFocusManager when it needs to so that the CCTVFocusManager's
 *  handling of panning to another control doesn't interact with the controls internal handler.
 *
 *  An example use of this is a potentiometer, used to set the volume of music.  The user would pan to focus the potentiometer
 *  click to activate it (which causes this method to return YES) and then pan to adjust the value of the volume.  Clicking
 *  then deactivates and returns panning control back to the CCTVFocusManager instance.
 */
- (BOOL) wantsControlOfTouch;

/**
 *  This method is for those times when you have an animation to highlight focus of a control and you want to restart it without
 *  removing focus altogether.
 */
- (void) resetFocus;

/**
 *  The angle of touch is an angle in degrees (where 0 is north, moving CW) where the angle represents the direction the users
 *  touch on the remote in relation to the start of a pan gesture.  The position of touch is irrelevant as the remote doesn't
 *  have a meaningful coordinate system.  By using this angle, the control can then assume that the touch is inside its
 *  frame (bacause it has focus), and it can then apply actions based on the angle.  For example, you can calculate a point on
 *  a circle at a radius from the center of the control at the specified angle to indicate a relative position of touch
 *  so that the control can behave as if it would normally on iOS.
 *
 *  @param angleInDegrees is the angle
 *  @param firstAngle is YES if this is the first touch in a pan gesture.
 *  @param lastAngle is YES if this is the last touch in a pan gesture.
 */
- (void) setAngleOfTouch:(float)angleInDegrees withRadius:(float)radius firstTime:(BOOL)firstAngle lastTime:(BOOL)lastAngle;

/**
 *  Activates the control, just like any other control.  This was included to ensure that classes that <em>don't</em> subclass
 *  CCControl support "activation" via a click.
 */
- (void) activate;

@optional

/**
 *  When the focus manager's playPauseAction property is set to kPlayPauseNotifies, the focus manager will call this method (if
 *  it exists whenever the play/pause button is pressed.
 */
- (void) playerDidPressPlayPause;

@end
