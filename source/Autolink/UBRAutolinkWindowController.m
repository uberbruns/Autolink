//
//  UBRAutolinkWindowController.m
//  Autolink
//
//  Created by Karsten Bruns on 13/03/14.
//  Copyright (c) 2014 Karsten Bruns. All rights reserved.
//

#import "UBRAutolinkWindowController.h"
#import "UBRAutolinkEngine.h"

@interface UBRAutolinkWindowController ()

@property (nonatomic, copy) NSURL * sourceFolder;
@property (nonatomic, copy) NSURL * targetFolder;
@property (nonatomic, strong) UBRAutolinkEngine * autolinkEngine;

@end



@implementation UBRAutolinkWindowController

#pragma mark - Life Cycle -

- (id)initWithWindowNibName:(NSString *)windowNibName {

    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        self.autolinkEngine = [[UBRAutolinkEngine alloc] init];
    }
    return self;

}


#pragma mark - Actions -

#pragma mark Interface Builder

- (IBAction)selectSourceFolder:(id)sender {
    
    [self selectFolder:self.sourceFolderField key:@"sourceFolder"];
    
}



- (IBAction)selectTargetFolder:(id)sender {
    
    [self selectFolder:self.targetFolderField key:@"targetFolder"];
    
}


- (IBAction)dismissProgressWindow:(id)sender {
    
    [self.window endSheet:self.progressWindow];
    
}



- (IBAction)openHelp:(id)sender {
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/uberbruns/Autolink#usage"]];
    
}


- (IBAction)createTargetStructure:(id)sender {
    
    NSFileManager * fm = [NSFileManager defaultManager];
    
    // Test User Input
    self.sourceFolder = [NSURL fileURLWithPath:self.sourceFolderField.stringValue isDirectory:TRUE];
    self.targetFolder = [NSURL fileURLWithPath:self.targetFolderField.stringValue isDirectory:TRUE];
    
    BOOL sourceFolderExists, targetFolderExists, sourceFolderIsFolder, targetFolderIsFolder;
    sourceFolderExists = [fm fileExistsAtPath:self.sourceFolder.path isDirectory:&sourceFolderIsFolder];
    targetFolderExists = [fm fileExistsAtPath:self.sourceFolder.path isDirectory:&targetFolderIsFolder];
    
    if (!sourceFolderExists || !targetFolderExists || !sourceFolderIsFolder || !targetFolderIsFolder) {
        self.sourceFolder = nil;
        self.targetFolder = nil;
        return;
    }
    
    // Show Progress Windows
    [self showProgress:TRUE];
    [self.window beginSheet:self.progressWindow completionHandler:nil];
    
    // Start Syncing
    [self.autolinkEngine clearTargetFolder:self.targetFolder];
    [self.autolinkEngine syncSourceFolder:self.sourceFolder withTargetFolder:self.targetFolder];
    
    // Close Progress Window  (We show it at least 0.25 sec)
    [self performSelector:@selector(dismissProgressWindow:) withObject:nil afterDelay:0.25];
    [self performSelector:@selector(showProgress:) withObject:[NSNumber numberWithBool:FALSE] afterDelay:0.5];
    
}



#pragma mark Abstract Actions

- (void)selectFolder:(NSTextField *)field key:(NSString*)key {

    NSOpenPanel * openDialog = [NSOpenPanel openPanel];
    
    [openDialog setCanChooseFiles:FALSE];
    [openDialog setCanChooseDirectories:TRUE];
    [openDialog setAllowsMultipleSelection:FALSE];
    [openDialog setDirectoryURL:[NSURL fileURLWithPath:[[NSUserDefaults standardUserDefaults] objectForKey:key]]];
    
    [openDialog beginWithCompletionHandler:^(NSInteger result) {
        
        if (result == 1) {
            
            NSString * filePath = nil;
            for (NSURL * url in openDialog.URLs) {
                filePath = [url path];
            }
            
            if (filePath) {
                field.stringValue = filePath;
            }
            
            [[NSUserDefaults standardUserDefaults] setObject:filePath forKey:key];
            [[NSUserDefaults standardUserDefaults] synchronize];

        }
        
    }];

}


#pragma mark User Interface Updates

- (void)showProgress:(BOOL)show {
    
    if (show) {
        [self.progressBar setIndeterminate:TRUE];
        [self.progressBar startAnimation:nil];
        [self.doneButton setEnabled:FALSE];
        [self.doneButton setTitle:@"Wait …"];
    } else {
        [self.progressBar setMaxValue:1.0];
        [self.progressBar setDoubleValue:0.0];
        [self.progressBar stopAnimation:nil];
        [self.progressBar setIndeterminate:FALSE];
        [self.doneButton setTitle:@"Done"];
        [self.doneButton setEnabled:TRUE];
    }
    
}





@end
