//
//  UBRAppDelegate.h
//  Autolink
//
//  Created by Karsten Bruns on 13/03/14.
//  Copyright (c) 2014 Karsten Bruns. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NSWindowController;

@interface UBRAppDelegate : NSObject <NSApplicationDelegate>

- (void)openNewWindow;

@property (nonatomic, strong) NSWindowController * keyWindowController;

@end
