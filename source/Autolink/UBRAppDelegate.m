//
//  UBRAppDelegate.m
//  Autolink
//
//  Created by Karsten Bruns on 13/03/14.
//  Copyright (c) 2014 Karsten Bruns. All rights reserved.
//

#import "UBRAppDelegate.h"
#import "UBRAutolinkWindowController.h"

@implementation UBRAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    [self openNewWindow];
    
}


- (void)openNewWindow {
    
    self.keyWindowController = [[UBRAutolinkWindowController alloc] initWithWindowNibName:@"UBRAutolinkWindowController"];
    [self.keyWindowController showWindow:nil];
    
}


- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)hasVisibleWindows {
    
    if (!hasVisibleWindows) {
        [self openNewWindow];
        return NO;
    }
    
    return YES;
    
}



@end
