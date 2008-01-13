#import "BSSpotlighter.h"

#import "BSSToolbar.h"
#import "BSSExpParser.h"

#import "BSSUtil.h"

@interface NSApplication(BSSFolders)
- (NSString *)applicationSupportFolder;
@end

enum {
	kAllSearchMenuItem = 100,
	kTitleSearchMenuItem,
	kContentsSearchMenuItem,
	kNameSearchMenuItem,
};

@interface BSSpotlighter(HMPrivate)
- (NSMetadataQuery *)createQuery;
- (NSPredicate *)createPredicate;

- (void)setCurrentPredicateForMenuItem:(id)item;

- (NSTableColumn *)makeColumnForIdentifier:(NSString *)identifier;
- (void)restoreFromUserDefaults;
- (void)buildTableHeaderViewMenu;
@end


static NSString *CustomTableViewStateKey = @"CustomTableViewState";

@implementation BSSpotlighter

-(id)init
{
	if(self = [super init]) {
		mCurrentKeys = [[NSArray arrayWithObjects:(id)kMDItemTitle, kMDItemTextContent, kMDItemContributors, nil] retain];
	}
	
	return self;
}
- (void)awakeFromNib
{
	[mTableView setTarget:self];
	[mTableView setDoubleAction:@selector(openSelections:)];
	
	id ppp = [BSSToolbar sharedInstance];
	[mWindow setToolbar:[ppp toolbar]];
	[mWindow setShowsToolbarButton:NO];
	
	[self restoreFromUserDefaults];
	[self buildTableHeaderViewMenu];
	[[mTableView headerView] setMenu:mTableHeaderMenu];
	
	id viewMenu = [[NSApp mainMenu] itemWithTag:400];
	[viewMenu setSubmenu:mTableHeaderMenu];
}

- (void)openThread:(id)path
{
	[[NSWorkspace sharedWorkspace] openFile:path];
}

-(void)openFinderInfoWindowWithPath:(NSString *)filePath
{
	openInfomationInFinderWithPath(filePath);
}
- (void)saveTableViewColumns
{
	//	tableHeader の表示の有無を保存。
	NSArray *columns;
	id enume, obj;
	NSMutableArray *culumStates;
	
	culumStates = [NSMutableArray array];
	
	columns = [mTableView tableColumns];
	enume = [columns objectEnumerator];
	while(obj = [enume nextObject]) {
		id identifier = [obj identifier];
		id width = [NSNumber numberWithFloat:[obj width]];
		[culumStates addObject:identifier];
		[culumStates addObject:width];
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:culumStates forKey:CustomTableViewStateKey];
}

#pragma mark## Key Value Coding ##
- (NSArray *)currentKeys
{
	return mCurrentKeys;
}
- (void)setCurrentKeys:(NSArray *)array
{
	id temp = mCurrentKeys;
	mCurrentKeys = [array retain];
	[temp release];
}
- (id)foundListController
{
	return mFoundListController;
}

#pragma mark## Actions ##
- (IBAction)changePredicate:(id)sender
{
	if([sender isKindOfClass:[NSMenuItem class]]) {
		[self setCurrentPredicateForMenuItem:sender];
	}
	[self createPredicate];
}
- (IBAction)openSelections:(id)sender
{
	id rows;
	id enume, obj;
	
	rows = [[self foundListController] selectedObjects];
	enume = [rows objectEnumerator];
	while(obj = [enume nextObject]) {
		[self openThread:[obj valueForKey:(NSString *)kMDItemPath]];
	}
}
- (IBAction)showHideHeader:(id)sender
{
	if(![sender isKindOfClass:[NSMenuItem class]]) return;
	
	id identifier = [sender representedObject];
	if(!identifier || ![identifier isKindOfClass:[NSString class]]) return;
	
	id col = [mTableView tableColumnWithIdentifier:identifier];
	if(!col) {
		col = [self makeColumnForIdentifier:identifier];
		if(col) {
			[mTableView addTableColumn:col];
		}
	} else {
		[mTableView removeTableColumn:col];
	}
}
- (IBAction)openInfomationInFinder:(id)sender
{
	id rows;
	id enume, obj;
	
	rows = [[self foundListController] selectedObjects];
	enume = [rows objectEnumerator];
	while(obj = [enume nextObject]) {
		[self openFinderInfoWindowWithPath:[obj valueForKey:(NSString *)kMDItemPath]];
	}
}
	

#pragma mark## NSApplication Delegate ##
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}
- (void)applicationWillTerminate:(NSNotification *)notification
{
	[self saveTableViewColumns];
}

#pragma mark## NSWindow Delegate ##
- (void)windowWillClose:(NSNotification *)notification
{
	[self saveTableViewColumns];
}

#pragma mark## NSMenu Delegate ##
- (void)menuNeedsUpdate:(NSMenu*)menu
{
	if(menu != mTableHeaderMenu) return;
	
	// turn off state all menu items.
	{
		NSArray *items = [menu itemArray];
		id enume = [items objectEnumerator];
		id obj;
		
		while(obj = [enume nextObject]) {
			[obj setState:NSOffState];
		}
	}
	
	NSArray *columns = [mTableView tableColumns];
	id enume = [columns objectEnumerator];
	id obj;
	
	while(obj = [enume nextObject]) {
		id title = [[obj headerCell] title];
		id item = [menu itemWithTitle:title];
		[item setState:NSOnState];
	}
}
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	SEL selector = [menuItem action];
	
	if(selector == @selector(openInfomationInFinder:) ||
	   selector == @selector(openSelections:)) {
		if([[[self foundListController] selectedObjects] count] == 0) {
			return NO;
		}
	}
	
	return YES;
}

@end

@implementation BSSpotlighter(HMPrivate)

#pragma mark## Result NSTableView ##

- (NSArray *)headerViewItemList
{
	NSString *path = [[NSBundle mainBundle] pathForResource:@"HeaderViewMenuItems" ofType:@"plist"];
	
	return [NSArray arrayWithContentsOfFile:path];
}
- (NSDictionary *)headerViewItemProperty
{
	static NSDictionary *result = nil;
	
	if(!result) {
		@synchronized(self) {
			if(!result) {
				NSArray *array =  [self headerViewItemList];
				NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:[array count]];
				
				id enume, obj;
				enume = [array objectEnumerator];
				while(obj = [enume nextObject]) {
					[dict setObject:[obj objectForKey:@"displayName"]
							 forKey:[obj objectForKey:@"identifier"]];
				}
				
				result = [[NSDictionary dictionaryWithDictionary:dict] retain];
			}
		}
	}
	
	return result;
}
- (NSString *)headerTitleForIdentifier:(NSString *)identifier
{
	return [[self headerViewItemProperty] objectForKey:identifier];
}

- (NSArray *)headerViewIdentifiers
{
	return [[self headerViewItemProperty] allKeys];
}
- (void)clearHeaderViews
{
	NSArray *columns;
	id enume, obj;
	
	columns = [mTableView tableColumns];
	enume = [columns objectEnumerator];
	while(obj = [enume nextObject]) {
		[mTableView removeTableColumn:obj];
	}
}
- (NSTableColumn *)makeColumnForIdentifier:(NSString *)identifier
{
	NSTableColumn *col;
	NSString *colTitle = [self headerTitleForIdentifier:identifier];
	
	col = [[[NSTableColumn alloc] initWithIdentifier:identifier] autorelease];
	[col setEditable:NO];
	[[col headerCell] setTitle:colTitle];
	[col bind:@"value"
	 toObject:[self foundListController]
  withKeyPath:[NSString stringWithFormat:@"arrangedObjects.%@", identifier]
	  options:nil];
	
	return col;
}
- (void)restoreFromUserDefaults
{
	NSArray *state = [[NSUserDefaults standardUserDefaults] arrayForKey:CustomTableViewStateKey];
	unsigned count;
	NSMutableArray *cols;
	
	if(!state) return;
	if((count=[state count]) == 0) return;
	if(count % 2) return;
	
	unsigned i;
	NSString *identifier;
	NSNumber *width;
	NSTableColumn *col;
	NSString *colTitle;
	
	cols = [NSMutableArray array];
	for(i = 0; i < count; i += 2) {
		identifier = [state objectAtIndex:i];
		width = [state objectAtIndex:i + 1];
		
		if(![identifier isKindOfClass:[NSString class]]) {
			return;
		}
		if(![width isKindOfClass:[NSNumber class]] || [width floatValue] < 2) {
			return;
		}
		colTitle = [self headerTitleForIdentifier:identifier];
		if(!colTitle || [colTitle length] == 0) {
			return;
		}
		
		col = [self makeColumnForIdentifier:identifier];
		if(!col) return;
		
		[col setWidth:[width floatValue]];
		[cols addObject:col];
	}
	
	[self clearHeaderViews];
	
	for(i = 0, count = [cols count]; i < count; i++) {
		[mTableView addTableColumn:[cols objectAtIndex:i]];
	}
}

- (void)buildTableHeaderViewMenu
{
	if(!mTableHeaderMenu) {
		mTableHeaderMenu = [[NSMenu alloc] initWithTitle:@"View"];
		[mTableHeaderMenu setDelegate:self];
	}
	
	NSArray *array = [self headerViewIdentifiers];
	id enume = [array objectEnumerator];
	id obj;
	
	while(obj = [enume nextObject]) {
		id name = [self headerTitleForIdentifier:obj];
		
		id item = [[NSMenuItem alloc] initWithTitle:name
											 action:@selector(showHideHeader:)
									  keyEquivalent:@""];
		[item setTarget:self];
		[item setRepresentedObject:obj];
		
		[mTableHeaderMenu addItem:item];
	}
}
-(NSArray *)bsDocumentDirectory
{
	NSMutableArray *result = [NSMutableArray array];
	NSString *appSuportFolder;
	NSString *path;
	
	appSuportFolder = [NSApp applicationSupportFolder];
	path = [appSuportFolder stringByAppendingPathComponent:@"BathyScaphe"];
	path = [path stringByAppendingPathComponent:@"Documents"];
	[result addObject:path];
	
	return result;
}

#pragma mark -
- (NSMetadataQuery *)createQuery
{
	if(mQuery) return mQuery;
	
	[self willChangeValueForKey:@"mQuery"];
	
	mQuery = [[NSMetadataQuery alloc] init];
	if(!mQuery) return nil;
	
	[mQuery setSearchScopes:[self bsDocumentDirectory]];
	
	[self didChangeValueForKey:@"mQuery"];
	
	return mQuery;
}
- (NSPredicate *)createPredicate
{
	NSPredicate *predicate;
	NSString *cond;
	
	cond = [mSearchField stringValue];
	if(!cond || [cond length] == 0) {
		return nil;
	}
	
	id tokenzer = [BSSTokenizer tokenizerWithString:cond];
	id parser = [BSSExpParser sharedInstance];
	id f = [parser predicateStringForTokens:tokenzer forKey:@"$$KEY$$"];
	NSMutableString *predicate01;
	NSString *predicate02;
	
	{
		id enume = [[self currentKeys] objectEnumerator];
		id obj;
		NSMutableArray *array = [NSMutableArray array];
		
		while(obj = [enume nextObject]) {
			predicate01 = [NSMutableString stringWithString:f];
			[predicate01 replaceOccurrencesOfString:@"$$KEY$$"
										 withString:obj
											options:0
											  range:NSMakeRange(0, [predicate01 length])];
			NSString *str = [NSString stringWithFormat:@"(%@)", predicate01];
			[array addObject:str];
		}
		
		predicate02 = [array componentsJoinedByString:@" || "];
	}
	
	predicate02 = [NSString stringWithFormat:@"kMDItemContentType == \"jp.tsawada2.bathyscaphe.thread\" && (%@)", predicate02];
	predicate = [NSPredicate predicateWithFormat:predicate02];
	BSSLog(@"Tokens -> %@", predicate);
	
	if(!mQuery) {
		[self createQuery];
	}
	[mQuery setPredicate:predicate];
	if(![mQuery isStarted]) {
		[mQuery startQuery];
	}
	
	return predicate;
}

- (void)setCurrentPredicateForMenuItem:(id)item
{
	NSString *placeholder = [item title];
	
	switch([item tag]) {
		case kAllSearchMenuItem:
			[self setCurrentKeys:[NSArray arrayWithObjects:(id)kMDItemTitle, kMDItemTextContent, kMDItemContributors, nil]];
			break;
		case kTitleSearchMenuItem:
			[self setCurrentKeys:[NSArray arrayWithObject:(id)kMDItemTitle]];
			break;
		case kContentsSearchMenuItem:
			[self setCurrentKeys:[NSArray arrayWithObject:(id)kMDItemTextContent]];
			break;
		case kNameSearchMenuItem:
			[self setCurrentKeys:[NSArray arrayWithObject:(id)kMDItemContributors]];
			break;
		default:
			//
			break;
	}
	
	if(placeholder) {
		[[mSearchField cell] setPlaceholderString:placeholder];
	}
}

@end


@implementation NSApplication(BSSFolders)
- (NSString *)applicationSupportFolder
{
	OSErr err;
	FSRef ref;
	UInt8 path[PATH_MAX];
	
	err = FSFindFolder(kUserDomain, kApplicationSupportFolderType, YES, &ref);
	if( noErr != err) return nil;
	
	err = FSRefMakePath(&ref, path, PATH_MAX);
	if(noErr != err) return nil;
	
	return [[NSFileManager defaultManager] stringWithFileSystemRepresentation:(char *)path
																	   length:strlen((char *)path)];
}
@end
