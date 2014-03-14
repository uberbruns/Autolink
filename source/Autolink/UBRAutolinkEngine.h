//
//  UBRAutolinkEngine.h
//  Autolink
//
//  Created by Karsten Bruns on 14/03/14.
//  Copyright (c) 2014 Karsten Bruns. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UBRAutolinkEngine : NSObject

- (void)syncSourceFolder:(NSURL *)sourceFolderURL withTargetFolder:(NSURL *)targetFolderURL;
- (void)clearTargetFolder:(NSURL *)targetFolder;

@end
