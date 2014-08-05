//
//  GLACollectionViewController.h
//  Blik
//
//  Created by Patrick Smith on 30/07/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

#import "GLAViewController.h"
#import "GLACollection.h"

@interface GLACollectionViewController : GLAViewController

@property(nonatomic) GLACollection *collection;

//+ (void)registerViewControllerClass:(Class /*GLACollectionViewController*/)controllerClass forCollectionContentClass:(Class /*(GLACollectionContent)*/)contentClass;
//+ (Class)viewControllerClassForCollectionContentClass:(Class /*(GLACollectionContent)*/)contentClass;

@end
