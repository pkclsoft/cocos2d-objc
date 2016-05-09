//
//  CCTVFocusManagerStack.h
//
//  Created by Peter Easdown on 25/09/2015.
//

#import <Foundation/Foundation.h>

#import "CCTVFocusManager.h"

/**
 *  A simple stack for managing nesting of CCTVFocusManager objects.  Effectively provides a way for
 *  a tvOS app to handle focus management when swapping between scenes/layers.
 */
@interface CCTVFocusManagerStack : NSObject

/**
 *  Returns a singleton instance of CCTVFocusManagerStack.
 */
+ (CCTVFocusManagerStack*) sharedTVFocusManagerStack;

/**
 *  Disable whatever manager is currently on the top of the stack, and put this new manager onto the top
 *  ensuring it is enabled.
 */
- (void) pushManager:(CCTVFocusManager*)manager;

/**
 *  Pop the current manager off the stack, and enable the manager that is then on the top.
 */
- (CCTVFocusManager*) popManager;

/**
 *  Returns the currently active focus manager.
 */
- (CCTVFocusManager*) currentManager;

@end
