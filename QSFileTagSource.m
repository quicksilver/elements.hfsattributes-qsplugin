//
//  QSFileTagSource.m
//
//  Created by Jordan Kay on 2/5/12.
//  Adapted for File Tagging by Rob McBroom on 2013/09/09
//

#import "FileTaggingHandler.h"
#import "QSFileTagSource.h"
#import "QSObject+FileTags.h"

@implementation QSFileTagSource

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry
{
    // always rescan to pick up recent changes
    return NO;
}

- (NSArray *)objectsForEntry:(NSDictionary *)entry
{
    NSSet *tagNames = [[FileTaggingHandler sharedHandler] allTagNames];
    NSMutableArray *tags = [NSMutableArray array];
    for(NSString *tagName in tagNames) {
        QSObject *tag = [QSObject fileTagWithName:tagName];
        [tags addObject:tag];
    }
    return tags;
}

- (NSString *)detailsOfObject:(QSObject *)object
{
    if ([[object identifier] containsString:kQSFileTagTransient]) {
        // leave details alone for transient tags
        return nil;
    } else {
        // effectively suppress details by making them equal to name
        return [object displayName];
    }
}

- (BOOL)loadChildrenForObject:(QSObject *)object
{
    NSMutableArray *children = [NSMutableArray array];
    // check for transient tag when navigating
    NSString *tagListString = [object objectForCache:kQSFileTagList];
    if (!tagListString) {
        // a normal tag from the catalog
        tagListString = [object label];
    }
    [children addObjectsFromArray:[[FileTaggingHandler sharedHandler] filesAndRelatedTagsForTagList:tagListString]];
    [object setChildren:children];
    return YES;
}

- (BOOL)objectHasChildren:(QSObject *)object
{
    return YES;
}

- (NSImage *)iconForEntry:(NSDictionary *)entry
{
    return kQSFileTagIcon;
}

- (void)setQuickIconForObject:(QSObject *)object
{
    [object setIcon:kQSFileTagIcon];
}

- (BOOL)loadIconForObject:(QSObject *)object
{
    [self setQuickIconForObject:object];
    return YES;
}

@end
