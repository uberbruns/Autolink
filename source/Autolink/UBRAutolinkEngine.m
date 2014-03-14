//
//  UBRAutolinkEngine.m
//  Autolink
//
//  Created by Karsten Bruns on 14/03/14.
//  Copyright (c) 2014 Karsten Bruns. All rights reserved.
//

#import "UBRAutolinkEngine.h"

@implementation UBRAutolinkEngine


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
