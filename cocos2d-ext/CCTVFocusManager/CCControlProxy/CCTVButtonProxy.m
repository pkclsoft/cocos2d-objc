//
//  CCTVButtonProxy.m
//
//  Created by Peter Easdown on 18/12/2015.
//

#import "CCTVButtonProxy.h"
#import "CCControlSubclass.h"

@implementation CCTVButtonProxy

+ (CCTVButtonProxy*) proxyForButton:(CCTVButton*)button {
    return [[CCTVButtonProxy alloc] initWithControl:button];
}

@end
