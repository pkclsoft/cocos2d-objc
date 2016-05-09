//
//  CCTVTextFieldProxy.h
//
//  Created by Peter Easdown on 18/12/2015.
//  Copyright © 2015 PKCLsoft. All rights reserved.
//

#import "CCFocusableTextField.h"
#import "CCFocusableControlProxy.h"

@interface CCTVTextFieldProxy : CCFocusableControlProxy

+ (CCTVTextFieldProxy*) proxyForTextField:(CCFocusableTextField*)textField;

@end
