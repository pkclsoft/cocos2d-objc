//
//  CCTVFocusManager.m
//
//  Created by Peter Easdown on 23/09/2015.
//

#import "CCTVFocusManager.h"
#import "CCTVFocusManagerStack.h"
#import "cocos2d.h"
#import "CCControl.h"
#import "CCControlSubclass.h"

@interface CCTVFocusManager() <UIGestureRecognizerDelegate>

/**
 *  The pan recognizer for this manager - is used alongside the swipeRecognizer for the focus management.
 */
@property (nonatomic) UIPanGestureRecognizer *panRecognizer;

/**
 *  The swipe recognizer for this manager - is used alongside the panRecognizer for the focus management.
 */
@property (nonatomic) UISwipeGestureRecognizer *swipeRecognizer;

/**
 *  The tap recognizer - this handles presses on the touchpad itself.
 */
@property (nonatomic) UITapGestureRecognizer *tapRecognizer;

/**
 *  A recognizer for the remote "menu" button.  This is only created if the
 *  backControl property is set.
 */
@property (nonatomic) UITapGestureRecognizer *menuButtonRecognizer;

/**
 *  A recognizer for the remote "play/pause" button.  This is only created if the
 *  playPauseAssumesPanControl property is set to YES.
 */
@property (nonatomic) UITapGestureRecognizer *playPauseButtonRecognizer;

/**
 *  This is a simple action to provide a visual indication that a control has focus.  It is only
 *  used for controls that do not conform to the CCFocusableControl protocol.
 */
@property (nonatomic) CCActionRepeatForever *focusAction;

/**
 *  This is the scale of the focused control when it receives focus so that it can be restored
 *  when focus moves away.  It is only used for controls that do not conform to the
 *  CCFocusableControl protocol.
 */
@property (nonatomic) float focusedControlScale;

@end

/**
 *  This subclass of CCActionScaleTo is used to scale a focused control back down to it's "normal", or
 *  "unfocused" scale.  This is used by setFocusedControl: to ensure that when an control is given focus
 *  we remember correctly, the "unfocused" scale.
 */
@interface CCActionScaleTo_CCTVFocusManager : CCActionScaleTo

/// The end scale for the action.
@property (nonatomic) float endScale;

@end

@implementation CCActionScaleTo_CCTVFocusManager

/**
 *  Returns the end scale for the action, taken from the super._endScaleX.
 */
- (float) endScale {
    return _endScaleX;
}

@end

@implementation CCTVFocusManager {
    
    /// The start point of a pan touch.
    CGPoint startPoint;
    
    /// The start point of a swipe
    CGPoint swipeStartPoint;
    
    /**
     *  These flags are initialised when a control is given focus as a way to simply
     *  know at any time what sort of control it is.
     */
    BOOL focusedControlIsFocusable;
    BOOL focusedControlIsControl;
}

#define kFocusLostActionTag 1002
#define kFocusedActionTag 1004

/**
 *  Initialises the manager with defaults.
 */
- (id) init {
    self = [super init];
    
    if (self != nil) {
        _enabled = NO;
        _focusedControl = nil;
        focusedControlIsFocusable = NO;
        focusedControlIsControl = NO;
        _focusAction = nil;
        _focusedControlScale = 1.0;
        _panControlActive = YES;
        _playPauseAction = kPlayPauseNone;
        self.positionType = CCPositionTypeNormalized;
        self.position = CGPointMake(0.5, 0.5);
        self.anchorPoint = CGPointMake(0.5, 0.5);
        self.contentSizeType = CCSizeTypeNormalized;
        self.contentSize = CGSizeMake(1.0, 1.0);
        
        [self addPanRecognizer];
        [self addSwipeRecognizer];
        [self addTapRecognizers];
    }
    
    return self;
}

/**
 *  Initialises the manager and populates it with the specified array of controls.
 *
 *  This subclass relaxes the rule regarding the need for the controls to be subclasses of
 *  CCControl.
 */
-(id) initWithArray:(NSArray *)arrayOfControls
{
    if( (self=[super init]) ) {
        int z=0;
        
        for( CCNode *control in arrayOfControls) {
            [self addChild: control z:z];
            z++;
        }
        
        [self addPanRecognizer];
        [self addSwipeRecognizer];
        [self addTapRecognizers];
        
        self.focusedControl = nil;
        focusedControlIsFocusable = NO;
        focusedControlIsControl = NO;
        _focusAction = nil;
        _focusedControlScale = 1.0;
        _panControlActive = YES;
        _playPauseAction = kPlayPauseNone;
        
        [self findFirstFocusableControl];
    }
    
    return self;
}

/**
 *  Cleans up the menu prior to deallocation.
 */
- (void) cleanup {
    [super cleanup];
    
    [self removePanRecognizer];
    [self removeSwipeRecognizer];
    [self removeTapRecognizers];
    
    if (self.focusAction != nil) {
        [[self focusAction] stop];
        self.focusAction = nil;
    }
    
    if (self.backControl != nil) {
        _backControl = nil;
    }
    
    [[CCTVFocusManagerStack sharedTVFocusManagerStack] popManager];
}

/**
 *  When the CCTVFocusManager is added to the node tree, push it onto the CCTVFocusManagerStack.
 */
- (void) onEnter {
    [super onEnter];
    
    [[CCTVFocusManagerStack sharedTVFocusManagerStack] pushManager:self];
}

- (void) onEnterTransitionDidFinish {
    [super onEnterTransitionDidFinish];
    
    self.enabled = YES;
}

/**
 *  Overrides addChild so that children are allowed to also implement the
 *  CCFocusableMenuITem protocol.
 */
-(void) addChild:(CCNode*)child z:(NSInteger)z name:(NSString *)name
{
    NSAssert(([child isKindOfClass:[CCControl class]] == YES) ||
             ([child conformsToProtocol:@protocol(CCFocusableControl)] == YES),
             @"CCTVFocusManager only supports CCControl objects as children");
    [super addChild:child z:z name:name];
    
//    CCLOG(@"new child [%@] at: %@", name, NSStringFromCGPoint(child.positionInPoints));
    
    if (_focusedControl == nil) {
        [self findClosestFocusableControl];
    }
}

- (void) removeChild:(CCNode *)node cleanup:(BOOL)cleanup {
    // First, if the node is the focused node, then move focus.
    //
    if (node == [self focusedNode]) {
        [self findClosestFocusableControl];
    }

    [super removeChild:node cleanup:cleanup];
}

-(void) removeChildByName:(NSString *)name
{
    [self removeChildByName:name cleanup:YES];
}

-(void) removeChildByName:(NSString *)name cleanup:(BOOL)cleanup
{
    NSAssert( name, @"Invalid name");
    
    CCNode *child = [self getChildByName:name recursively:NO];
    
    if (child == nil)
        CCLOG(@"cocos2d: removeChildByName: child not found!");
    else
        [self removeChild:child cleanup:cleanup];
}


/**
 *  When the menu is re-enabled, it can re-apply focus to
 *  whatever control was in focus prior to the menu being disabled.
 */
- (void) setEnabled:(BOOL)enabled {
    NSLog(@"CCTVFocusManager Enabled: %@ in parent: %@", (enabled ? @"YES" : @"NO"), [[self.parent class] description]);

    _enabled = enabled;
    
    if (enabled == YES) {
        if ([self focusedNode] != nil) {
            if (focusedControlIsFocusable == NO) {
                // Before we do this, we need to reset the scale of the control so that restarting the focus scaling
                // action doesn't use the wrong scale as the starting point.
                //
                [[self focusedNode] setScale:_focusedControlScale];
            }
            
            [self startFocus];
        }
    }
}

/**
 *  Sets the "back" or "close" button that will be activated when the user presses the "menu"
 *  button on the remote.
 */
- (void) setBackControl:(id)backControl {
    _backControl = backControl;
    
    _backControl.visible = NO;
    
    [self addTapRecognizers];
}

/**
 *  Sets the action desired when the user presses the play/pause button.  This is provided so
 *  that you have a way to use the play/pause button in a way that suites your app.
 */
- (void) setPlayPauseAction:(PlayPauseButtonAction)playPauseAction {
    if (playPauseAction != _playPauseAction) {
        _playPauseAction = playPauseAction;
        
        // By default, a CCTVFocusManager will have control over pan gestures, regardless of the action type.
        //
        _panControlActive = YES;
    }
}

/**
 *  Returns the control that currently has focus as a CCControl.
 */
- (CCControl<CCFocusableControl>*) focusedCCControl {
    return (CCControl<CCFocusableControl>*)self.focusedControl;
}

/**
 *  Returns the control that currently has focus as a CCFocusableControl.
 */
- (NSObject<CCFocusableControl>*) focusedObject {
    return (NSObject<CCFocusableControl>*)self.focusedControl;
}

/**
 *  Returns the control that currently has focus as a CCNode
 */
- (CCNode*) focusedNode {
    return (CCNode*)self.focusedControl;
}

/**
 *  Causes the CCTVFocusManager to search through it's children for the first control that is:
 *
 *  1. enabled
 *  2. not the backControl
 *
 * @note This also sets panControlActive to YES.
 */
- (void) findFirstFocusableControl {
    BOOL done = NO;
    
    [_children enumerateObjectsUsingBlock:^(CCControl<CCFocusableControl>* control, NSUInteger idx, BOOL * _Nonnull stop) {
        if ((done == NO) && (control != _backControl) && (control.isEnabled == YES)) {
            [self setFocusedControl:control];
            *stop = YES;
        }
    }];
    
    // Assume that if the app wants an control to be focused, then the menu gets control of panning
    //
    _panControlActive = YES;
}

/**
 *  Locates the control that is closest to the current focused control and shifts focus to it.
 */
- (void) findClosestFocusableControl {
    [self findClosestFocusableControlToPositionInPoints:[self focusedNode].positionInPoints];
}

/**
 *  Locates the control that is closest to the specified position and shifts focus to it.
 */
- (void) findClosestFocusableControlToPositionInPoints:(CGPoint)positionInPoints {
    __block CCControl<CCFocusableControl>* closestControl = nil;
    __block float closestDistance = MAXFLOAT;
    
    for (CCControl<CCFocusableControl>* control in _children) {
        if ((control != [self focusedNode]) && (control != _backControl) && (control.isEnabled == YES)) {
            float thisDistance = ccpDistance(positionInPoints, control.positionInPoints);
            
            if (thisDistance < closestDistance) {
                closestControl = control;
                closestDistance = thisDistance;
            }
        }
    }
    
    if (closestControl != nil) {
        [self setFocusedControl:closestControl];
        
        // Assume that if the app wants an control to be focused, then the menu gets control of panning
        //
        _panControlActive = YES;
    } else {
        NSLog(@"Unable to find another closer control");
    }
}

/**
 *  Causes the CCTVFocusManager to search through it's children for the next control that is:
 *
 *  1. enabled
 *  2. not the backControl
 *  3. not the currently focused control.
 */
- (void) findNextFocusableControl {
    if (self.focusedControl == nil) {
        [self findFirstFocusableControl];
    } else {
        // Where is the current focused control?
        //
        NSUInteger currentIndex = [_children indexOfObject:self.focusedControl];
        NSUInteger searchIndex = currentIndex + 1;
        
        if (currentIndex == _children.count-1) {
            // It is the last control in the array, so in that case, find the first focusable control.
            //
            [self findFirstFocusableControl];
        } else {
            // Not the last, so search forward, wrapping around at the end, and finish if we get
            // back to the same point.
            //
            NSUInteger newIndex = NSNotFound;
            
            while ((newIndex == NSNotFound) && (searchIndex != currentIndex)) {
                // If the search has gone beyond the end of the array, then loop back to the start.
                //
                if (searchIndex >= _children.count) {
                    searchIndex = 0;
                }
                
                CCControl<CCFocusableControl>* control = [_children objectAtIndex:searchIndex];
                
                if (control == self.focusedControl) {
                    // This shouldn't be necessary, but as a protection...
                    //
                    searchIndex = currentIndex;
                } else if ((control != _backControl) && (control.isEnabled == YES)) {
                    newIndex = searchIndex;
                } else {
                    searchIndex++;
                }
            }
            
            // Found one, so move focus to it.
            //
            if (newIndex != NSNotFound) {
                [self setFocusedControl:[_children objectAtIndex:newIndex]];
            }
        }
    }
}

/**
 *  Sets the currently focused control, shifting focus visually as required.
 */
- (void) setFocusedControl:(id<CCFocusableControl>)focusedControl {
    if (_focusedControl != focusedControl) {
        CCLOG(@"setFocusedControl: current %@", [self focusedNode]);
        CCLOG(@"setFocusedControl: new %@", (CCNode*)focusedControl);
        
        if (_focusedControl != nil) {
            [self resetFocus];
        }
        
        _focusedControl = focusedControl;
        
        if (_focusedControl != nil) {
            focusedControlIsFocusable = [[self focusedObject] conformsToProtocol:@protocol(CCFocusableControl)];
            
            focusedControlIsControl = [[self focusedObject] isKindOfClass:[CCControl class]];
            
            [self startFocus];
        }
    }
}

/**
 *  Set the focused control to be the specified node (which may not implement the CCFocusableControl protocol).
 */
- (void) setFocusedNode:(id)node {
    [self setFocusedControl:node];
}

/**
 *  Gives focus to the focused control.  If the control implements CCFocusableControl, then
 *  the control is told that is is focused.
 *
 *  If the control is a regular CCControl then the focus os visually indicated using a simple
 *  scale-wobble.
 */
- (void) startFocus {
    CCLOG(@"startFocus: %@", [self focusedNode]);
    
    if (focusedControlIsFocusable == YES) {
        self.focusedControl.focused = YES;
    } else {
        // This is an non-focusable control, so simply scale it up.
        //
        _focusedControlScale = [self focusedNode].scale;
        
        // Just in case the control was in the act of de-focusing when it regained focus, ensure we get the right
        // "unfocused" scale.
        //
        CCNode *node = [self focusedNode];
        
        // Is the only action running the "lost focus" action?
        //
        CCActionInterval *action = (CCActionInterval*)[node getActionByTag:kFocusLostActionTag];
        
        // If so, then cast it, and grab the endScale as that will be the scale that the control needs as it's
        // unfocused scale.
        //
        if (action != nil) {
            CCActionScaleTo_CCTVFocusManager *scaleToAction = (CCActionScaleTo_CCTVFocusManager*)action;
            _focusedControlScale = scaleToAction.endScale;
        }
        
        if ([node getActionByTag:kFocusedActionTag] == nil) {
            self.focusAction = [CCActionRepeatForever actionWithAction:
                                [CCActionSequence actions:
                                 [CCActionScaleTo actionWithDuration:0.5 scale:_focusedControlScale * 1.2],
                                 [CCActionScaleTo actionWithDuration:0.5 scale:_focusedControlScale * 1.15],
                                 nil]];
            self.focusAction.tag = kFocusedActionTag;
            
            [node runAction:_focusAction];
            
        }
    }
    
    if ((focusedControlIsControl == YES) && (self.parent != nil)) {
        [self focusedCCControl].selected = YES;
    }
}

/**
 *  Resets the focus of the focused control, effectively turning the focus animation off.
 */
- (void) resetFocus {
    CCLOG(@"resetFocus: %@", [self focusedNode]);
    
    if (focusedControlIsFocusable == YES) {
        _focusedControl.focused = NO;
    } else {
        [[self focusedNode] stopActionByTag:kFocusedActionTag];
        self.focusAction = nil;
        
        CCActionScaleTo_CCTVFocusManager *action = [CCActionScaleTo_CCTVFocusManager actionWithDuration:0.4 scale:_focusedControlScale];
        action.tag = kFocusLostActionTag;
        
        [[self focusedNode] runAction:action];
    }
    
    if ((focusedControlIsControl == YES) && (self.parent != nil)) {
        [self focusedCCControl].selected = NO;
    }
}

/**
 * Override normal CCMenu behaviour.
 */
-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    return NO;
}

/**
 * Override normal CCMenu behaviour.
 */
-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
}

/**
 * Override normal CCMenu behaviour.
 */
-(void) ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
}

/**
 * Override normal CCMenu behaviour.
 */
-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
}

#pragma mark -
#pragma mark Gesture code

// Ensures that the menu still works with the gesture recognizer.
//
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {

    if (_enabled == YES) {
        return ((gestureRecognizer == _panRecognizer) && (_panControlActive == YES)) ||
        ((gestureRecognizer == _swipeRecognizer) && (_panControlActive == YES)) ||
        (gestureRecognizer == _tapRecognizer) ||
        (gestureRecognizer == _menuButtonRecognizer) ||
        (gestureRecognizer == _playPauseButtonRecognizer);
    } else {
        return NO;
    }
}

/**
 *  Important that if you are handling press events, this returns YES.
 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceivePress:(UIPress *)press {
    return self.enabled;
}

/**
 *  This is essential if you want a Pan gesture recognizer to work alongside a press or tap recognizer.
 */
- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}


#pragma mark - Pan Gesture code

- (float) angleFromPoint:(CGPoint)from toPoint:(CGPoint)to {
    CGPoint pnormal = ccpSub(to, from);
    float radians = atan2f(pnormal.x, pnormal.y);
    
    return radians;
}

- (void) panned:(UIPanGestureRecognizer*)recognizer {
    if (_enabled == NO) {
        return;
    }
    
    CGPoint b = [[CCDirector sharedDirector] convertToGL:[recognizer locationInView:recognizer.view]];
    
    float angle = fmodf((360.0 + CC_RADIANS_TO_DEGREES([self angleFromPoint:startPoint toPoint:b])), 360.0);
    
    if([recognizer state] == UIGestureRecognizerStateBegan) {
        startPoint = b;

        if ([self focusedObject].wantsAngleOfTouch == YES) {
            [[self focusedObject] setAngleOfTouch:angle withRadius:0.0 firstTime:YES lastTime:NO];
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        BOOL controlChanged = [self handlePanInDirection:angle
                                         withDistance:ccpDistance(b, startPoint)];
        
        if (controlChanged == YES) {
            startPoint = b;
        }
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        if ([self focusedObject].wantsAngleOfTouch == YES) {
            [[self focusedObject] setAngleOfTouch:angle withRadius:ccpDistance(b, startPoint) firstTime:NO lastTime:YES];
        }
    }
}

/// A distance that the pan must traverse in a straight line for a focus change to occur.
#define NEXT_ITEM_THRESHOLD (350.0)

/// This is the maximum variance between the direction of the pan, and the direction from the start of the pan
/// to the control being examined as a candidate for the next focus.
#define PAN_DIRECTION_PROXIMITY (25.0)

- (BOOL) handlePanInDirection:(float)direction withDistance:(float)distance {
    if (_focusedControl != nil) {
        // If the control is interested in tracking the touch, and actively wants control of the touch, then
        // give this touch to the control.
        //
        if (([self focusedObject].wantsAngleOfTouch == YES) && ([self focusedObject].wantsControlOfTouch == YES)) {
            
            [[self focusedObject] setAngleOfTouch:direction withRadius:distance firstTime:NO lastTime:NO];
            
            // Otherwise, if the control isn't currently interested, and the touch is in a straight line, then see if there is
            // another control in that direction.
            //
        } else if (distance > NEXT_ITEM_THRESHOLD) {
            if (([self focusedObject].wantsAngleOfTouch == NO) ||
                (([self focusedObject].wantsAngleOfTouch == YES) && ([self focusedObject].wantsControlOfTouch == NO))) {
                return [self findNextControlInDirection:direction];
            }
        }
    }
    
    return NO;
}

/**
 *  Searches for other controls in the direction specified, and locates the closest.
 */
- (BOOL) findNextControlInDirection:(float)direction {
    CCControl<CCFocusableControl> *nextControl = nil;
    float bestDistance = MAXFLOAT;
    float bestAngle = MAXFLOAT;
    
    for (CCControl<CCFocusableControl>* control in _children) {
        if ((control != _backControl) && (control != _focusedControl) && (control.isEnabled == YES)) {
            float angleToControl = fmodf((360.0 + CC_RADIANS_TO_DEGREES([self angleFromPoint:[self focusedNode].positionInPoints toPoint:control.positionInPoints])), 360.0);
            float distanceToControl = ccpDistance([self focusedNode].positionInPoints, control.positionInPoints);
            float angleDelta = fabsf(fabsf(angleToControl) - fabsf(direction));
            
            if ((angleDelta <= PAN_DIRECTION_PROXIMITY) &&
                (angleDelta <= bestAngle) &&
                (distanceToControl < bestDistance)) {
                nextControl = control;
                bestDistance = distanceToControl;
                bestAngle = angleDelta;
            }
        }
    }
    
    if ((nextControl != nil) && (nextControl != _focusedControl)) {
        [self setFocusedControl:nextControl];
        
        return YES;
    } else {
        return NO;
    }
}

- (void) addPanRecognizer {
    if (_panRecognizer != nil) {
        [self removePanRecognizer];
    }
    
    _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)];
    _panRecognizer.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeSelect]];
    [_panRecognizer setDelegate:self];
    
    [[CCDirector sharedDirector].view addGestureRecognizer:_panRecognizer];
    
    NSLog(@"CCTVFocusManager Pan recognizer added");
}

- (void) removePanRecognizer {
    if (_panRecognizer != nil) {
        [_panRecognizer setDelegate:nil];
        [[CCDirector sharedDirector].view removeGestureRecognizer:_panRecognizer];
        _panRecognizer = nil;
        
        NSLog(@"CCTVFocusManager Pan recognizer removed");
    }
}

#pragma mark - Swipe Gesture code

- (void) addSwipeRecognizer {
    if (_swipeRecognizer != nil) {
        [self removePanRecognizer];
    }
    
    _swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swiped:)];
    
    _swipeRecognizer.direction =
    UISwipeGestureRecognizerDirectionDown | UISwipeGestureRecognizerDirectionLeft |
    UISwipeGestureRecognizerDirectionRight | UISwipeGestureRecognizerDirectionUp;
    
    [_swipeRecognizer setDelegate:self];
    
    [[CCDirector sharedDirector].view addGestureRecognizer:_swipeRecognizer];
    
    NSLog(@"CCTVFocusManager Swipe recognizer added");
}

- (void) removeSwipeRecognizer {
    if (_swipeRecognizer != nil) {
        [_swipeRecognizer setDelegate:nil];
        [[CCDirector sharedDirector].view removeGestureRecognizer:_swipeRecognizer];
        _swipeRecognizer = nil;
        
        NSLog(@"CCTVFocusManager Swipe recognizer removed");
    }
}

- (void) swiped:(UISwipeGestureRecognizer*)recognizer {
    if (_enabled == NO) {
        return;
    }
    
    CGPoint b = [[CCDirector sharedDirector] convertToGL:[recognizer locationInView:recognizer.view]];
    
    float angle = fmodf((360.0 + CC_RADIANS_TO_DEGREES([self angleFromPoint:swipeStartPoint toPoint:b])), 360.0);
    
    if([recognizer state] == UIGestureRecognizerStateBegan) {
        // This never seems to be called.  Swipe Gestures only ever "end".
        swipeStartPoint = b;
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        if ([self focusedObject].wantsControlOfTouch == NO) {
            [self findNextControlInDirection:angle];
        }
    }
}

#pragma mark - Tap Gesture code

- (void) tapped:(UITapGestureRecognizer*)recognizer {
    if ((_enabled == NO) || ([[self focusedControl] isEnabled] == NO)) {
        return;
    }
    
    if (focusedControlIsControl == YES) {
        [[self focusedControl] activate];
    } else if (focusedControlIsFocusable == YES) {
        [[self focusedObject] activate];
    }
}

- (void) menuPressed:(UITapGestureRecognizer*)recognizer {
    if (_enabled == NO) {
        return;
    }
    
    if (_backControl != nil) {
        if ([_backControl conformsToProtocol:@protocol(CCFocusableControl)] == YES) {
            [((CCNode<CCFocusableControl>*) _backControl) activate];
        } else if ([_backControl isKindOfClass:[CCControl class]] == YES) {
            [(CCControl*)_backControl triggerAction];
        }
    }
}

- (void) playPausePressed:(UITapGestureRecognizer*)recognizer {
    if (_enabled == NO) {
        return;
    }
    
    switch (_playPauseAction) {
        case kPlayPauseTogglesPanControl: {
            if (_panControlActive == YES) {
                _panControlActive = NO;
            } else {
                _panControlActive = YES;
            }
        }
            break;
        case kPlayPauseShiftsFocus: {
            [self findNextFocusableControl];
        }
            break;
            
        case kPlayPauseNotifies: {
            if ([self.focusedControl respondsToSelector:@selector(playerDidPressPlayPause)] == YES) {
                [self.focusedControl playerDidPressPlayPause];
            }
        }
            break;
            
        case kPlayPauseNone:
            break;
    }
}

- (void) addTapRecognizers {
    if (_tapRecognizer != nil) {
        [self removeTapRecognizers];
    }
    
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    _tapRecognizer.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeSelect]];
    [_tapRecognizer setDelegate:self];
    
    [[CCDirector sharedDirector].view addGestureRecognizer:_tapRecognizer];
    
    _playPauseButtonRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playPausePressed:)];
    _playPauseButtonRecognizer.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypePlayPause]];
    [_playPauseButtonRecognizer setDelegate:self];
    
    [[CCDirector sharedDirector].view addGestureRecognizer:_playPauseButtonRecognizer];
    
    if (_backControl != nil) {
        _menuButtonRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(menuPressed:)];
        _menuButtonRecognizer.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeMenu]];
        [_menuButtonRecognizer setDelegate:self];
        
        [[CCDirector sharedDirector].view addGestureRecognizer:_menuButtonRecognizer];
    }
    
    NSLog(@"CCTVFocusManager Tap/press recognizers added");
}

- (void) removeTapRecognizers {
    if (_tapRecognizer != nil) {
        [_tapRecognizer setDelegate:nil];
        [[CCDirector sharedDirector].view removeGestureRecognizer:_tapRecognizer];
        
        NSLog(@"CCTVFocusManager Tap recognizer removed");
    }
    
    if (_playPauseButtonRecognizer != nil) {
        [_playPauseButtonRecognizer setDelegate:nil];
        [[CCDirector sharedDirector].view removeGestureRecognizer:_playPauseButtonRecognizer];
        
        NSLog(@"CCTVFocusManager playpause button recognizer removed");
    }
    
    if (_menuButtonRecognizer != nil) {
        [_menuButtonRecognizer setDelegate:nil];
        [[CCDirector sharedDirector].view removeGestureRecognizer:_menuButtonRecognizer];
        
        NSLog(@"CCTVFocusManager menu button recognizer removed");
    }
}

@end
