//
//  CCTVTextFieldProxy.m
//
//  Created by Peter Easdown on 18/12/2015.
//

#import "CCTVTextFieldProxy.h"

@implementation CCTVTextFieldProxy

+ (CCTVTextFieldProxy*) proxyForTextField:(CCFocusableTextField*)textField {
    return [[CCTVTextFieldProxy alloc] initWithControl:textField];
}

@end
