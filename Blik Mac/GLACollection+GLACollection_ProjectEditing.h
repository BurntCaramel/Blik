//
//  GLACollection+GLACollection_ProjectEditing.h
//  Blik
//
//  Created by Patrick Smith on 12/10/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLACollection.h"


@interface GLACollection (GLACollection_ProjectEditing)

@property(readwrite, weak, nonatomic) GLAProject *project;

@end
