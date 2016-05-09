//
//  CCTVButtonProxy.h
//
//  Created by Peter Easdown on 18/12/2015.
//

#import "CCTVButton.h"
#import "CCFocusableControlProxy.h"

@interface CCTVButtonProxy : CCFocusableControlProxy

+ (CCTVButtonProxy*) proxyForButton:(CCTVButton*)button;

@end
