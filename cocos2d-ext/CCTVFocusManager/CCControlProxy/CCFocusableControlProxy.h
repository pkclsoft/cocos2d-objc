//
//  CCFocusableControlProxy.h
//
//  Created by Peter Easdown on 18/12/2015.
//

#import "CCControl.h"
#import "CCFocusableControl.h"
#import "CCControlProxy.h"

@interface CCFocusableControlProxy : CCControl <CCFocusableControl>

@property (nonatomic) CCControl<CCFocusableControl, CCControlProxy> *control;

- (id) initWithControl:(CCControl<CCFocusableControl, CCControlProxy>*)control;

+ (CCFocusableControlProxy*) proxyForControl:(CCControl<CCFocusableControl, CCControlProxy>*)control;

@end
