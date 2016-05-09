//
//  CCTVFocusManagerStack.m
//
//  Created by Peter Easdown on 25/09/2015.
//

#import "CCTVFocusManagerStack.h"

@interface CCTVFocusManagerStack()

/**
 *  The internal stack.
 */
@property (nonatomic, retain) NSMutableArray *stack;

@end

/**
 *  A simple stack for managing nesting of CCTVFocusManager objects.  Effectively provides a way for
 *  a tvOS app to handle focus management when swapping between scenes/layers.
 */
@implementation CCTVFocusManagerStack

/**
 *  Default initialiser.
 */
- (id) init {
    self = [super init];
    
    if (self != nil) {
        self.stack = [NSMutableArray arrayWithCapacity:5];
    }
    
    return self;
}

/**
 * A static instance of this class.  You should only need one stack in a given app.
 */
static CCTVFocusManagerStack *static_tvFocusMangerStack = nil;

/**
 *  Returns a singleton instance of CCTVFocusManagerStack.
 */
+ (CCTVFocusManagerStack*) sharedTVFocusManagerStack {
    if (static_tvFocusMangerStack == nil) {
        static_tvFocusMangerStack = [[CCTVFocusManagerStack alloc] init];
    }
    
    return static_tvFocusMangerStack;
}

/**
 *  Disable whatever manager is currently on the top of the stack, and put this new manager onto the top
 *  ensuring it is enabled.
 */
- (void) pushManager:(CCTVFocusManager*)manager {
    // In an ideal world, this check wouldn't be needed, but due to the fact that cleanup of nodes can happen out of
    // sequence with what is happening on screen, we do.
    //
    if ([_stack containsObject:manager] == NO) {
        if (_stack.count > 0) {
            ((CCTVFocusManager*)[_stack lastObject]).enabled = NO;
        }
        
        [_stack addObject:manager];
        
        CCLOG(@"pushManager, remaining: %lu", (unsigned long)_stack.count);
    }
}

/**
 *  Pop the current manager off the stack, and enable the manager that is then on the top.
 */
- (CCTVFocusManager*) popManager {
    [_stack removeLastObject];
    
    CCLOG(@"popManager, remaining: %lu", (unsigned long)_stack.count);
    
    CCTVFocusManager *newManager = ((CCTVFocusManager*)[_stack lastObject]);
    
    if (newManager != nil) {
        newManager.enabled = YES;
    
        return newManager;
    } else {
        NSAssert(false, @"CCTVFocusManagerStack exhausted.");
    }
    
    return nil;
}

/**
 *  Returns the currently active focus manager.
 */
- (CCTVFocusManager*) currentManager {
    return ((CCTVFocusManager*)[_stack lastObject]);;
}

@end
