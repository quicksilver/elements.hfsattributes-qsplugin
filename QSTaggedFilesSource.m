//
//  QSTaggedFilesSource.m
//
//  Created by Rob McBroom on 2013/02/18.
//

#import "QSTaggedFilesSource.h"
#import "FileTaggingHandler.h"

@implementation QSTaggedFilesSource
@synthesize tagsTokenField;

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry
{
    // always rescan
    return NO;
}

- (NSArray *)objectsForEntry:(NSDictionary *)theEntry
{
    NSDictionary *settings = [theEntry objectForKey:kItemSettings];
    NSString *tagList = [[settings objectForKey:@"tags"] componentsJoinedByString:@","];
    return [[FileTaggingHandler sharedHandler] filesWithTagList:tagList];
}

#pragma mark Catalog Entry UI

- (BOOL)isVisibleSource
{
    return YES;
}

- (NSImage *) iconForEntry:(NSDictionary *)theEntry
{
    return kQSFileTagIcon;
}

- (NSView *)settingsView
{
    if (![super settingsView]) {
        [NSBundle loadNibNamed:NSStringFromClass([self class]) owner:self];
    }
    return [super settingsView];
}

- (void)populateFields
{
    NSMutableDictionary *settings = [[self currentEntry] objectForKey:kItemSettings];
    [tagsTokenField setObjectValue:[settings objectForKey:@"tags"]];
}

#pragma mark Token Field Delegate

- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(NSInteger *)selectedIndex
{
    NSMutableArray *knownTags = [NSMutableArray array];
    for (NSString *tagData in [[FileTaggingHandler sharedHandler] allTagNames]) {
        [knownTags addObject:[tagData lines][0]];
    }
    NSArray *completions = [knownTags filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginswith[cd] %@", substring]];
    return completions;
}

- (void)controlTextDidEndEditing:(NSNotification *)notif
{
    NSMutableDictionary *settings = [[self currentEntry] objectForKey:kItemSettings];
	if (!settings) {
		settings = [NSMutableDictionary dictionaryWithCapacity:1];
		[[self currentEntry] setObject:settings forKey:kItemSettings];
	}
    [settings setObject:[tagsTokenField objectValue] forKey:@"tags"];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChangedNotification object:[self currentEntry]];
    [[self selection] scanAndCache];
}

@end
