//
//  GLACollectedFilesSetting.h
//  Blik
//
//  Created by Patrick Smith on 3/11/2014.
//  Copyright (c) 2014 Burnt Caramel. All rights reserved.
//

@import Foundation;
#import "GLACollectedFile.h"


@interface GLACollectedFilesSetting : NSObject

- (void)startUsingURLForCollectedFile:(GLACollectedFile *)collectedFile;
- (void)stopUsingURLForCollectedFile:(GLACollectedFile *)collectedFile;
- (void)stopUsingURLsForAllCollectedFiles;

- (void)startUsingURLsForCollectedFiles:(NSArray *)collectedFiles removingRemainders:(BOOL)removeRemainders;

@end
