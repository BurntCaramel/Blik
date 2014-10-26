//
//  GLAToggleButton.h
//  Blik
//
//  Created by Patrick Smith on 17/07/2014.
//  Copyright (c) 2014 Patrick Smith. All rights reserved.
//

#import "GLAButton.h"


@interface GLAToggleButtonCell : GLAButtonCell

@end


@interface GLAToggleButton : GLAButton

@property (nonatomic) GLAToggleButtonCell *cell;

@end
