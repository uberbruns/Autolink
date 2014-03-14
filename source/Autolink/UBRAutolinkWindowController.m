//
//  UBRAutolinkWindowController.m
//  Autolink
//
//  Created by Karsten Bruns on 13/03/14.
//  Copyright (c) 2014 Karsten Bruns. All rights reserved.
//

#import "UBRAutolinkWindowController.h"

@interface UBRAutolinkWindowController ()

@property (nonatomic, copy) NSURL * sourceFolder;
@property (nonatomic, copy) NSURL * targetFolder;

@end

@implementation UBRAutolinkWindowController


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
    [self clearTargetFolder:self.targetFolder];
    [self syncSourceFolder:self.sourceFolder withTargetFolder:self.targetFolder];
    
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


#pragma mark UI

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



#pragma mark - Core Functionality -

- (void)syncSourceFolder:(NSURL *)sourceFolderURL withTargetFolder:(NSURL *)targetFolderURL {
    
    NSFileManager * fm = [NSFileManager defaultManager];
    NSArray * sourceFolderComp = [sourceFolderURL pathComponents];
    NSDirectoryEnumerator * dirEnumerator = [fm enumeratorAtURL:sourceFolderURL
                                     includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey]
                                                        options:NSDirectoryEnumerationSkipsPackageDescendants
                                                   errorHandler:nil];
    
    
    // Iterate Over Source Files
    for (NSURL * fileURL in dirEnumerator) {
        
        // Create Link Token Found
        BOOL createLink = [[fileURL lastPathComponent] isEqualToString:@".createlink"];
        if (createLink) {
            
            NSError * error;
            NSUInteger srcCount = sourceFolderComp.count;
            NSUInteger thisCount = fileURL.pathComponents.count;
            NSArray * thisFolderComp = [fileURL.pathComponents subarrayWithRange:NSMakeRange(srcCount, thisCount-srcCount-2)];
            
            // Create New Target Folder
            NSArray * newFolderComp = [targetFolderURL.pathComponents arrayByAddingObjectsFromArray:thisFolderComp];
            NSURL * newFolderURL = [NSURL fileURLWithPathComponents:newFolderComp];
            [fm createDirectoryAtURL:newFolderURL withIntermediateDirectories:TRUE attributes:nil error:&error];
            if (error) {
                NSLog(@"Autolink could not create folder: %@", newFolderURL);
            }

            // Create Symlink
            NSString * symlink = fileURL.pathComponents[thisCount-2];
            NSURL * symLinkURL = [newFolderURL URLByAppendingPathComponent:symlink];
            NSURL * destionationURL = [fileURL URLByDeletingLastPathComponent];
            
            if (![fm fileExistsAtPath:symLinkURL.path]) {
                [fm createSymbolicLinkAtURL:symLinkURL withDestinationURL:destionationURL error:&error];
                if (error) {
                    NSLog(@"Autolink could not create symlink: %@", symLinkURL);
                }
            }
            
            
        }
        
    }
    
}



- (void)clearTargetFolder:(NSURL *)targetFolder {

    NSFileManager * fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator * dirEnumerator = [fm enumeratorAtURL:targetFolder
                                     includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey, NSURLIsSymbolicLinkKey]
                                                        options:NSDirectoryEnumerationSkipsPackageDescendants
                                                   errorHandler:nil];

    for (NSURL * fileURL in dirEnumerator.allObjects.reverseObjectEnumerator) {
        NSDictionary * attr = [fm attributesOfItemAtPath:fileURL.path error:nil];
        
        if (attr[NSFileType] == NSFileTypeSymbolicLink) {
            // Delete Symlinks
            [fm removeItemAtURL:fileURL error:nil];
        } else if (attr[NSFileType] == NSFileTypeDirectory) {
            // Delete Empty Folders
            NSArray * content = [fm contentsOfDirectoryAtPath:fileURL.path error:nil];
            if (content && content.count == 0) {
                [fm removeItemAtURL:fileURL error:nil];
            }
        }
    }
    
}



@end
