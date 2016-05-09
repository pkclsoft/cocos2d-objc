//
//  CCFocusableTextField.h
//
//  Created by Peter Easdown on 18/11/2015.
//
//  FIXME: NOTE THAT THIS CLASS WORKS, BUT ONLY 90%.  I've been unable to get proper control of focus
//  for text fields.
//

#import "CCTextField.h"
#import "CCFocusableControl.h"
#import "CCControlProxy.h"

@interface CCFocusableTextField : CCTextField <CCFocusableControl, CCControlProxy>

@end
