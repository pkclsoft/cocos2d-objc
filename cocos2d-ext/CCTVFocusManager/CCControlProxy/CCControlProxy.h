//
//  CCControl+Proxy.h
//
//  Created by Peter Easdown on 4/03/2016.
//
//

#import "CCControl.h"
#import "CCFocusableControl.h"
#import "CCControlProxy.h"

@protocol CCControlProxy

/**
 *  This reference is for those times when the control needing focus is the child of a scene or one of it's children
 *  and a proxy is used to represent the control to the CCTVFocusManager.
 */
@property (nonatomic) CCNode<CCFocusableControl> *proxy;

@end
