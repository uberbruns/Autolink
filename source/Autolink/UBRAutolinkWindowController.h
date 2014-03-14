//
//  UBRAutolinkWindowController.h
//  Autolink
//
//  Created by Karsten Bruns on 13/03/14.
//  Copyright (c) 2014 Karsten Bruns. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface UBRAutolinkWindowController : NSWindowController

- (IBAction)selectSourceFolder:(id)sender;
- (IBAction)selectTargetFolder:(id)sender;
- (IBAction)createTargetStructure:(id)sender;
- (IBAction)dismissProgressWindow:(id)sender;

@property (weak) IBOutlet NSTextField *sourceFolderField;
@property (weak) IBOutlet NSTextField *targetFolderField;

@property (strong) IBOutlet NSWindow *progressWindow;
@property (weak) IBOutlet NSProgressIndicator *progressBar;
@property (weak) IBOutlet NSButton *doneButton;
@property (assign) BOOL userHasBackups;


@end
