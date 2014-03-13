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

- (id)initWithWindow:(NSWindow *)window {
    
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
    
}



- (void)windowDidLoad {

    [super windowDidLoad];

}



- (IBAction)selectSourceFolder:(id)sender {
    
    [self selectFolder:self.sourceFolderField key:@"sourceFolder"];
    
}



- (IBAction)selectTargetFolder:(id)sender {
    
    [self selectFolder:self.targetFolderField key:@"targetFolder"];
    
}


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



- (IBAction)createTargetStructure:(id)sender {
    
    NSFileManager * fm = [NSFileManager defaultManager];

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

    [self showProgress:TRUE];
    [self.window beginSheet:self.progressWindow completionHandler:nil];

    [self clearTargetFolder:self.targetFolder];
    [self syncSourceFolder:self.sourceFolder withTargetFolder:self.targetFolder];

    [self performSelector:@selector(showProgress:) withObject:[NSNumber numberWithBool:FALSE] afterDelay:0.5];

}



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



- (IBAction)dismissProgressWindow:(id)sender {

    [self.window endSheet:self.progressWindow];

}



- (IBAction)openHelp:(id)sender {

    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/uberbruns/Autolink#usage"]];

}



- (void)syncSourceFolder:(NSURL *)currentSourceFolder withTargetFolder:(NSURL *)currentTargetFolder {
    
    NSFileManager * fm = [NSFileManager defaultManager];
    
    NSDirectoryEnumerator * dirEnumerator = [fm enumeratorAtURL:currentSourceFolder
                                     includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey]
                                                        options:NSDirectoryEnumerationSkipsPackageDescendants |
                                             NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                   errorHandler:nil];
    
    for (NSURL * fileURL in dirEnumerator) {
        
        BOOL hasCreateFolderToken, hasCreateLinkToken;
        hasCreateFolderToken = [fm fileExistsAtPath: [[fileURL URLByAppendingPathComponent:@".createfolder" isDirectory:0] path]];
        hasCreateLinkToken = [fm fileExistsAtPath: [[fileURL URLByAppendingPathComponent:@".createlink" isDirectory:0] path]];

        if (hasCreateFolderToken) {
            NSURL * newFolder = [self createFolder:fileURL.lastPathComponent atTargetURL:currentTargetFolder];
            if (newFolder) {
                [self syncSourceFolder:fileURL withTargetFolder:newFolder];
            }
        } else if (hasCreateLinkToken) {
            [self createLink:fileURL.lastPathComponent atTargetURL:currentTargetFolder destination:fileURL];
        }
        
    }

}


- (NSURL *)createFolder:(NSString *)name atTargetURL:(NSURL *)targetFolder {

    NSFileManager * fm = [NSFileManager defaultManager];
    NSURL * newFolder = [targetFolder URLByAppendingPathComponent:name isDirectory:TRUE];
    NSError * error;
    
    [fm createDirectoryAtURL:newFolder withIntermediateDirectories:TRUE attributes:nil error:&error];
    
    if (!error) {
        return newFolder;
    } else {
        return nil;
    }

}



- (NSURL *)createLink:(NSString *)name atTargetURL:(NSURL *)targetFolder destination:(NSURL *)destination {
    
    NSFileManager * fm = [NSFileManager defaultManager];
    NSURL * symLinkURL = [targetFolder URLByAppendingPathComponent:name isDirectory:TRUE];
    NSError * error;
    
    [fm createSymbolicLinkAtURL:symLinkURL withDestinationURL:destination error:&error];
    
    if (!error) {
        return symLinkURL;
    } else {
        return nil;
    }
    
}



- (BOOL)clearTargetFolder:(NSURL *)targetFolder {

    NSFileManager * fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator * dirEnumerator = [fm enumeratorAtURL:targetFolder
                                     includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey, NSURLIsSymbolicLinkKey]
                                                        options:NSDirectoryEnumerationSkipsPackageDescendants
                                                   errorHandler:nil];

    for (NSURL * fileURL in dirEnumerator.allObjects.reverseObjectEnumerator) {
        NSDictionary * attr = [fm attributesOfItemAtPath:fileURL.path error:nil];
        if (attr[NSFileType] == NSFileTypeSymbolicLink) {
        } else if (attr[NSFileType] == NSFileTypeDirectory) {
            NSArray * content = [fm contentsOfDirectoryAtPath:fileURL.path error:nil];
            if (content && content.count == 0) {
                [fm removeItemAtURL:fileURL error:nil];
            }
        }
    }
    
    return TRUE;
    
}



@end
