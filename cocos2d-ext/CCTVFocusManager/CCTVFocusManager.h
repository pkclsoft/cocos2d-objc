//
//  CCTVFocusManager.h
//
//  Created by Peter Easdown on 23/09/2015.
//
#import <Foundation/Foundation.h>
#import "CCNode.h"
#import "CCFocusableControl.h"

/**
 *  A class that provides a basic, yet functional focus management system for tvOS in Cocos2D 3+.  It supports
 *  the use of CCControl and it's subclasses, plus any objects that conform to the CCFocusableControl protocol.
 *
 *  The menu is intended to provide behaviour similar to that provided by Apple's UIKit focus manager on tvOS in that
 *  controls require focus to be given to them before they can be activated.
 *
 *  CCTVFocusManager works by allowing the user to pan from one control to another.  There is an internal distance threshold
 *  used to determine at what point in a straight-line pan the focus will move from one control to the next.  The 
 *  CCTVFocusManager uses the direction of the pan to determine which control is given focus.  It searches the enabled menu
 *  items for the closest control in a straight line within 25.0 degrees of the pan direction.
 *
 *  CCTVFocusManager also tries to respect Apple's UI Guidelines by using the Apple TV Remote's "menu" button to act as a
 *  trigger for the "back" button on your scene/layer/node.  By setting the backItem property, the CCTVFocusManager will hide
 *  that item from view, but will activate it if the "menu" button is pressed.  The backItem is also ignored for focus
 *  events.
 *
 *  Another class, CCTVFocusManagerStack is used to manage CCTVFocusManager instances.  Typically (at least in my apps), I create a
 *  CCTVFocusManager instance on each distinct scene/layer that the user is to interact with.  If you use CCTVFocusManager instead for
 *  each scene, then as the menu is realised (via onEnter), it pushes itself onto the static stack object.  When it
 *  does this, any other CCTVFocusManager instances are disabled.  When a CCTVFocusManager is cleaned up (via cleanup), it pops itself
 *  off the stack.  This way the application doesn't need to manage the enabling and disabling of menus (which is needed
 *  if you add a layer to your main game node that has it's own menu) and it all happens smoothly with little or no
 *  change to the existing code.
 */
@interface CCTVFocusManager : CCNode <UIGestureRecognizerDelegate>

/**
 *  This is the currently focused control.  Typically you won't need to examine this; it's used internally.
 */
@property (nonatomic) id<CCFocusableControl> focusedControl;

/**
 *  Is this manager enabled?
 */
@property (nonatomic) BOOL enabled;

/**
 *  This is the nominated "back" button for the scene/layer that the menu is the UI for.  CCTVFocusManager will hide this 
 *  item from view and prevent it from receiving focus.  Pressing "menu" on the remote will activate this control.
 */
@property (nonatomic) CCNode *backControl;

typedef enum {
    /**
     *  The play/pause button is not used.
     */
    kPlayPauseNone,
    
    /**
     *  This value offers a way for an app (probably a game) to have two modes of operation for the remote touchpad.
     *  If your game uses gesture recognizers to manipulate a character for example and you need be able to give give
     *  control to the player instead of focus management, then use this property.  Setting it to YES causes the CCTVFocusManager
     *  to recognise press events on the "play/pause" button on the remote.  When this button is pressed, it toggles
     *  the panControlActive property.  When that property is set to YES, CCTVFocusManager will ignore pan gestures, allowing your
     *  app to use it's own pan gesture recognizer for other things.
     */
    kPlayPauseTogglesPanControl,
    
    /**
     *  This value offers an alternative way to handle a situation where you have live action and the simultaneous need
     *  to be able to focus on, and activate buttons on the screen.  In this case, the play/pause button is used to move
     *  focus from one button to the next.  This means that panning doesn't need to swap from game action to menus and back
     *  again which might be difficult to use.
     */
    kPlayPauseShiftsFocus,
    
    /**
     *  This value instructs the focus manager to notify the delegate when the user presses the play/pause button.  This allows
     *  the app to respond to the play/pause button without needing to set up it's own gesture recognizers.
     */
    kPlayPauseNotifies
    
} PlayPauseButtonAction;

@property (nonatomic) PlayPauseButtonAction playPauseAction;

/**
 *  This property, when YES causes the CCTVFocusManager instance to ignore pan gestures.
 */
@property (nonatomic) BOOL panControlActive;

/**
 *  Causes the CCTVFocusManager to search through it's children for the first item that is:
 *
 *  1. enabled
 *  2. not the backItem
 *
 * @note This also sets panControlActive to YES.
 */
- (void) findFirstFocusableControl;

/**
 *  Causes the CCTVFocusManager to search through it's children for the next item that is:
 *
 *  1. enabled
 *  2. not the backItem
 *  3. not the currently focused item.
 */
- (void) findNextFocusableControl;

/**
 *  Locates the control that is closest to the current focused item and shifts focus to it.
 */
- (void) findClosestFocusableControlToPositionInPoints:(CGPoint)positionInPoints;

/**
 *  Set the focused item to be the specified node (which may not implement the CCFocusableControl protocol).
 */
- (void) setFocusedNode:(id)node;

/**
 *  Returns the control that currently has focus as a CCNode
 */
- (CCNode*) focusedNode;

#pragma mark - Adding controls.

/**
 *  Initialises the manager with defaults.
 */
- (id) init;

/**
 *  Initialises the manager and populates it with the specified array of controls.
 *
 *  This subclass relaxes the rule regarding the need for the items to be subclasses of
 *  CCMenuControl.
 */
-(id) initWithArray:(NSArray *)arrayOfControls;

@end
