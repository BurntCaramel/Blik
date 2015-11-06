//
//  DevMateInlines.h
//  DevMateKit
//
//  Copyright (c) 2014-2015 DevMate Inc. All rights reserved.
//

#import <objc/runtime.h>
#import <DevMateKit/DMFeedbackController.h>
#import <DevMateKit/DMIssuesController.h>
#import <DevMateKit/DMTrackingReporter.h>

// --------------------------------------------------------------------------
// Most inline functions here should be used only for DEBUG configuration.
// You can easily modify any implementation to cover your needs.
// --------------------------------------------------------------------------

#if !__has_feature(objc_arc)
#   define DM_AUTORELEASE(v) ([v autorelease])
#   pragma clang diagnostic push
#   pragma clang diagnostic ignored "-Wreserved-id-macro"
#   define __bridge
#   pragma clang diagnostic pop
#else // -fobjc-arc
#   define DM_AUTORELEASE(v) (v)
#endif

DM_INLINE void DMKitSetupSandboxLogSystem(void)
{
    // As you know, ASL API has no access to system log in sandboxed application.
    // Thats why we override standard stdout and stderr with our file that will be
    // accessible in sandbox.
    
#ifdef DEBUG
    // No need to do that in DEBUG to be available to see our logs in console.
    return;
#endif

    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(__bridge NSString *)kCFBundleNameKey];
    NSString *logFilePath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    logFilePath = [logFilePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@.log", appName, appName]];

    NSString *parentDirectory = [logFilePath stringByDeletingLastPathComponent];
    if (![[NSFileManager defaultManager] fileExistsAtPath:parentDirectory])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:parentDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }

    const char *logFilePathStr = [logFilePath fileSystemRepresentation];
    freopen(logFilePathStr, "a+", stderr);
    freopen(logFilePathStr, "a+", stdout);

    printf("\n\n");
    fflush(stdout);
    NSLog(@"==============================================================");
    NSLog(@"NEW LAUNCH (%@)", [[NSDate date] description]);

    NSArray *allLogFiles = [NSArray arrayWithObject:[NSURL fileURLWithPath:logFilePath]];
    [DMFeedbackController sharedController].logURLs = allLogFiles;
    [DMIssuesController sharedController].logURLs = allLogFiles;
}

#pragma mark - DevMate Debug Menu

@protocol DevMateKitDelegate <  DMTrackingReporterDelegate,
                                DMFeedbackControllerDelegate,
                                DMIssuesControllerDelegate >
@end

#ifndef DEBUG

#define DMKitDebugGetDevMateMenu() (nil)
#define DMKitDebugGetDevMateMenuItem(a,b,c) (nil)
#define DMKitDebugAddFeedbackMenu()
#define DMKitDebugAddIssuesMenu()
#define DMKitDebugAddDevMateMenu()

#else // defined(DEBUG)

@interface NSApplication (com_devmate_DebugExtensions)
- (IBAction)com_devmate_ShowFeedback:(id)sender;
- (IBAction)com_devmate_ThrowException:(id)sender;
- (IBAction)com_devmate_CrashApp:(id)sender;
@end


DM_INLINE NSMenu *DMKitDebugGetDevMateMenu(void)
{
    static NSString *debugMenuTitle = @"DevMate Debug";

    NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
    NSMenuItem *debugMenuItem = [mainMenu itemWithTitle:debugMenuTitle];
    if (nil == debugMenuItem)
    {
        debugMenuItem = DM_AUTORELEASE([[NSMenuItem alloc] initWithTitle:debugMenuTitle action:NULL keyEquivalent:@""]);
        debugMenuItem.submenu = DM_AUTORELEASE([[NSMenu alloc] initWithTitle:debugMenuTitle]);
        [mainMenu addItem:debugMenuItem];
    }
    
    return debugMenuItem.submenu;
}

typedef void (^DMKitDebugActionBlock)(id self, id sender);
DM_INLINE NSMenuItem *DMKitDebugGetDevMateMenuItem(NSString *title, SEL appAction, DMKitDebugActionBlock impBlock)
{
    NSMenuItem *menuItem = DM_AUTORELEASE([[NSMenuItem alloc] initWithTitle:title action:appAction keyEquivalent:@""]);
    menuItem.target = [NSApplication sharedApplication];

    const char *types = method_getTypeEncoding(class_getInstanceMethod([NSApplication class], @selector(terminate:)));
    class_addMethod([NSApplication class], appAction, imp_implementationWithBlock(impBlock), types);

    return menuItem;
}

DM_INLINE void DMKitDebugAddFeedbackMenu(void)
{
    static NSString *menuItemTitle = @"Show Feedback Dialog";
    
    NSMenu *debugMenu = DMKitDebugGetDevMateMenu();
    if (nil == [debugMenu itemWithTitle:menuItemTitle])
    {
        NSMenuItem *feedbackMenuItem = DMKitDebugGetDevMateMenuItem(menuItemTitle, @selector(com_devmate_ShowFeedback:), ^(id self, id sender) {
            [[DMFeedbackController sharedController] showWindow:nil];
        });
        [debugMenu addItem:feedbackMenuItem];
    }
}

DM_INLINE void DMKitDebugAddIssuesMenu(void)
{
    static NSString *exceptionMenuTitle = @"Throw Test Exception";
    static NSString *crashMenuTitle = @"Crash Application";
    
    NSMenu *debugMenu = DMKitDebugGetDevMateMenu();
    if (nil == [debugMenu itemWithTitle:exceptionMenuTitle])
    {
        NSMenuItem *exceptionMenuItem = DMKitDebugGetDevMateMenuItem(exceptionMenuTitle, @selector(com_devmate_ThrowException:), ^(id self, id sender) {
            [NSException raise:@"Test exception" format:@"This exception was thrown to test DevMate issues feature."];
        });
        [debugMenu addItem:exceptionMenuItem];
        
        NSMenuItem *crashMenuItem = DMKitDebugGetDevMateMenuItem(crashMenuTitle, @selector(com_devmate_CrashApp:), ^(id self, id sender) {
            *(int *)1 = 0;
        });
        [debugMenu addItem:crashMenuItem];
    }
}


DM_INLINE void DMKitDebugAddDevMateMenu(void)
{
    DMKitDebugAddFeedbackMenu();
    DMKitDebugAddIssuesMenu();
}

#endif // DEBUG
