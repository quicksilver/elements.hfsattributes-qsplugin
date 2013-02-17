

#import "QSHFSAttributeActions.h"



# define kHFSInvisibleAction @"QSHFSMakeInvisibleAction"
# define kHFSVisibleAction @"QSHFSMakeVisibleAction"
# define kHFSLockAction @"QSHFSLockAction"
# define kHFSUnlockAction @"QSHFSUnlockAction"
# define kHFSSetLabelAction @"QSHFSSetLabelAction"
# define kClearCustomIconAction @"QSClearCustomFileIconAction"


@implementation QSHFSAttributeActions

- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject{
    NSArray *paths=[dObject validPaths];
    NSMutableSet *newActions=[NSMutableSet setWithCapacity:2];
    @autoreleasepool {
        if (paths){
            for (NSString *path in paths) {
                NSURL *fileUrl = [NSURL fileURLWithPath:path];
                NSDictionary *info = [fileUrl resourceValuesForKeys:@[NSURLIsHiddenKey,NSURLIsWritableKey] error:nil];
                
                // File is locked?
                if ([[info objectForKey:NSURLIsWritableKey] boolValue]) {
                    [newActions addObject:kHFSLockAction];
                } else {
                    [newActions addObject:kHFSUnlockAction];
                }
                                
                // file is visible?
                if ([[info objectForKey:NSURLIsHiddenKey] boolValue]) {
                    [newActions addObject:kHFSVisibleAction];
                } else {
                    [newActions addObject:kHFSInvisibleAction];
                }
                
            }
        }
    }
    return [newActions allObjects];
}

- (NSArray *)labelObjectsArray{    
    NSMutableArray *objects=[NSMutableArray arrayWithCapacity:1];
    QSObject *newObject;
	
	NSMutableDictionary *labelsDict=[NSMutableDictionary dictionaryWithObjectsAndKeys:
		@"None",@"Label_Name_0",
		@"Gray",@"Label_Name_1",
		@"Green",@"Label_Name_2",
		@"Purple",@"Label_Name_3",
		@"Blue",@"Label_Name_4",
		@"Yellow",@"Label_Name_5",
		@"Red",@"Label_Name_6",
		@"Orange",@"Label_Name_7",
		nil];
	
	
	NSMutableDictionary *colorsDict=[NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSColor clearColor],@"Label_Name_0",
		[NSColor colorWithDeviceRed:0.56 green:0.56 blue:0.56 alpha:1.0],@"Label_Name_1",
		[NSColor colorWithDeviceRed:0.70 green:0.90 blue:0.25 alpha:1.0],@"Label_Name_2",
		[NSColor colorWithDeviceRed:0.79 green:0.55 blue:0.84 alpha:1.0],@"Label_Name_3",
		[NSColor colorWithDeviceRed:0.40 green:0.67 blue:1.0 alpha:1.0],@"Label_Name_4",
		[NSColor colorWithDeviceRed:0.95 green:0.94 blue:0.44 alpha:1.0],@"Label_Name_5",
		[NSColor colorWithDeviceRed:1.0 green:0.43 blue:0.40 alpha:1.0],@"Label_Name_6",
		[NSColor colorWithDeviceRed:1.0 green:0.73 blue:0.24 alpha:1.0],@"Label_Name_7",
		nil];

	[labelsDict addEntriesFromDictionary:
		[(NSDictionary *)CFPreferencesCopyMultiple((CFArrayRef)[labelsDict allKeys], (CFStringRef) @"com.apple.Labels", kCFPreferencesCurrentUser, kCFPreferencesAnyHost) autorelease]];
	NSUInteger i;
	for (i = 0; i < 8; i++){
		NSString *entry=[NSString stringWithFormat:@"Label_Name_%lu",(unsigned long)i];
		newObject=[QSObject objectWithName:[labelsDict objectForKey:entry]];
		[newObject setObject:[NSNumber numberWithInteger:i] forType:QSNumericType];
		[newObject setObject:[NSKeyedArchiver archivedDataWithRootObject:[colorsDict objectForKey:entry]] forType:NSColorPboardType];
		[newObject setPrimaryType:NSColorPboardType];
		[objects addObject:newObject];
	}
	
	return objects;
}

- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject{	
	if ([action isEqualToString:kHFSSetLabelAction]){
		return [self labelObjectsArray];
    }
	return nil;
}



- (BOOL)setPath:(NSString *)path isVisible:(BOOL)visible{
    OSStatus status = noErr;
    FSRef fsRef;
    
    status=FSPathMakeRef((const UInt8 *)[path UTF8String],&fsRef,NULL);
    
    if (status != noErr) return 0;
    
    FSCatalogInfo catalogInfo;
    status = FSGetCatalogInfo(& fsRef, kFSCatInfoFinderInfo,&catalogInfo, NULL, NULL, NULL);
    
    if (status != noErr) return 0;
    
    FileInfo* info = (FileInfo*)&catalogInfo.finderInfo;
    if (visible)
        info->finderFlags &= ~kIsInvisible;
    else
        info->finderFlags |= kIsInvisible;
    
    status = FSSetCatalogInfo(& fsRef, kFSCatInfoFinderInfo, &catalogInfo);
    
    return YES;
}

- (BOOL)setPath:(NSString *)path isLocked:(BOOL)locked{
    FSRef theRef;
    FSCatalogInfo catInfo;
    OSErr err=noErr;
    err=FSPathMakeRef((const UInt8 *)[path UTF8String],&theRef,NULL);
    // check for err here. noErr==0
    err=FSGetCatalogInfo(&theRef,kFSCatInfoNodeFlags,&catInfo,NULL,NULL,NULL);
    // check for err here.
    if (locked)
        catInfo.nodeFlags |= kFSNodeLockedMask;
    else
        catInfo.nodeFlags &= ~kFSNodeLockedMask;
    err=FSSetCatalogInfo(&theRef,kFSCatInfoNodeFlags,&catInfo);
    //check for err here.
    [[NSWorkspace sharedWorkspace] noteFileSystemChanged:path ];
    
    return YES;
}

- (QSObject *)makeInvisible:(QSObject *)dObject{
    NSString* path;
    NSEnumerator *pathEnumerator=[[dObject arrayForType:QSFilePathType]objectEnumerator];
    while (path=[pathEnumerator nextObject]){
        [self setPath:path isVisible:NO];
        [[NSWorkspace sharedWorkspace] noteFileSystemChanged:path ];
    }
    return nil;
}

- (QSObject *)makeVisible:(QSObject *)dObject{
    NSString* path;
    NSEnumerator *pathEnumerator=[dObject enumeratorForType:QSFilePathType];
    while (path=[pathEnumerator nextObject]){
        [self setPath:path isVisible:YES];
      //  [[NSWorkspace sharedWorkspace] noteFileSystemChanged:path ];
    }
    return nil;
}  

- (QSObject *)lock:(QSObject *)dObject{
    NSString* path;
    NSEnumerator *pathEnumerator=[dObject enumeratorForType:QSFilePathType];
    while (path=[pathEnumerator nextObject]){
        [self setPath:path isLocked:YES];
       // [[NSWorkspace sharedWorkspace] noteFileSystemChanged:[path stringByDeletingLastPathComponent]];
    }
    return nil;
}

- (QSObject *)unlock:(QSObject *)dObject{
    NSString* path;
    NSEnumerator *pathEnumerator=[dObject enumeratorForType:QSFilePathType];
    while (path=[pathEnumerator nextObject]){
        [self setPath:path isLocked:NO];
        //[[NSWorkspace sharedWorkspace] noteFileSystemChanged:[path stringByDeletingLastPathComponent]];
    }
    return nil;
}




// *** purify

- (void) setLabel:(NSInteger)label forPath:(NSString *)path{
    FSCatalogInfo info;
	FSRef par;
    Boolean dir = false;
    
	if (FSPathMakeRef((const UInt8 *)[path fileSystemRepresentation],&par,&dir) == noErr) {
        
        /* Get the Finder Catalog Info */
        OSErr err = FSGetCatalogInfo(&par,
                                     kFSCatInfoContentMod | kFSCatInfoFinderXInfo | kFSCatInfoFinderInfo,
                                     &info,
                                     NULL,
                                     NULL,
                                     NULL);
        
        if (err != noErr)
		{
            NSLog(@"Unabled to get catalog info... %i", err);
			return;
		}
        
        /* Manipulate the Finder CatalogInfo */
        UInt16 *flags = &((FileInfo*)(&info.finderInfo))->finderFlags;
        
        //To Turn off
        // *flags &= kColor;
        
        /*
         0 is off
         1 is Grey
         2 is Green
         3 is Purple
         4 is Blue
         5 is Yellow
         6 is Red
         7 is Orange
         */
        
        *flags = ( *flags &~ kColor) | ( (label << 1) & kColor );
        
        /* Set the Finder Catalog Info Back */
        err = FSSetCatalogInfo(&par,
                               kFSCatInfoContentMod | kFSCatInfoFinderXInfo | kFSCatInfoFinderInfo,
                               &info);
        
        if (err != noErr)
        {
            NSLog(@"Unable to set catalog info... %i", err);
            return;
        }
    }
}

- (QSObject *)setLabelForFile:(QSObject *)dObject to:(QSObject *)iObject{
    NSString* path;
	NSNumber *value=[iObject objectForType:QSNumericType];
	if (!value) return nil;
	NSInteger label=[value integerValue];
	//NSLog(@"setlabel %d",label);
    NSEnumerator *pathEnumerator=[dObject enumeratorForType:QSFilePathType];
    while (path=[pathEnumerator nextObject]){
		[self setLabel:label forPath:path];
        [[NSWorkspace sharedWorkspace] noteFileSystemChanged:path];
    }
    return nil;
}


- (QSObject *)setIconForFile:(QSObject *)dObject to:(QSObject *)iObject{
	NSWorkspace *w=[NSWorkspace sharedWorkspace];
    NSImage *icon;

    if (iObject) {
        NSString *sourcePath=[iObject singleFilePath];
        icon=[[[NSImage alloc] initWithContentsOfFile:sourcePath]autorelease];
        if (!icon) icon=[w iconForFile:sourcePath];
	} else {
        // setting the icon to 'nil' clears the custom icon
        icon = nil;
    }
    for (NSString *path in [dObject validPaths]){
        [w setIcon:icon forFile:path options:0];
		[w noteFileSystemChanged:path ];
    }
    return nil;
}

- (QSObject *)clearIconForFile:(QSObject *)dObject {
    return [self setIconForFile:dObject to:nil];
}

@end
