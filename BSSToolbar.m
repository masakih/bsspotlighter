//
//  BSSToolbar.m
//  BSSpotlighter
//
//  Created by Hori,Masaki on 06/05/15.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "BSSToolbar.h"

static NSString *BSSToolbarIdentifier = @"BSSToolbarIdentifier";
static NSString *BSSToolbarSearchFieldItemIdentifier = @"BSSToolbarSearchFieldItemIdentifier";
static NSString *BSSToolbarSpinItemIdentifier = @"BSSToolbarSpinItemIdentifier";
static NSString *BSSToolbarFoundNumItemIdentifier = @"BSSToolbarFoundNumItemIdentifier";

static BSSToolbar *sharedInstance = nil;

@implementation BSSToolbar

+ (id)sharedInstance
{
	@synchronized(self) {
		if(!sharedInstance) {
			sharedInstance = [[self alloc] init];
		}
	}
	
	return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
	@synchronized(self) {
		if(!sharedInstance) {
			return [super allocWithZone:zone];
		}
	}
	
	return sharedInstance;
}
- (id)copyWithZone:(NSZone *)zone
{
	return self;
}
- (id)retain{ return self; }
- (oneway void)release {}
- (unsigned)retainCount { return UINT_MAX; }
- (id)autorelease { return self; }
- (id)init
{
	if(sharedInstance) {
		[super init];
		[self release];
		return sharedInstance;
	}
	
	if(self = [super init]) {
		sharedInstance = self;
	}
	
	return self;
}

- (NSToolbar *)toolbar
{
	NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:BSSToolbarIdentifier] autorelease];
	
	[toolbar setDelegate:self];
	[toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
	
	return toolbar;
}

- (NSToolbarItem *)serachFieldItem
{
	NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:BSSToolbarSearchFieldItemIdentifier] autorelease];
	
	[item setView:searchField];
	[item setMinSize:NSMakeSize(100, NSHeight([searchField frame]))];
	[item setMaxSize:NSMakeSize(UINT_MAX, NSHeight([searchField frame]))];
	
	
	return item;
}
- (NSToolbarItem *)spinItem
{
	NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:BSSToolbarSearchFieldItemIdentifier] autorelease];
	
	[spin setStyle:NSProgressIndicatorSpinningStyle];
	
	[item setView:spin];
	[item setMinSize:NSMakeSize(NSWidth([spin frame]), NSHeight([spin frame]))];
	[item setMaxSize:NSMakeSize(NSWidth([spin frame]), NSHeight([spin frame]))];
	
	return item;
}
- (NSToolbarItem *)foundNumItem
{
	NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:BSSToolbarFoundNumItemIdentifier] autorelease];
		
	[item setView:foundNum];
	[item setMinSize:NSMakeSize(NSWidth([foundNum frame]), NSHeight([foundNum frame]))];
	[item setMaxSize:NSMakeSize(NSWidth([foundNum frame]), NSHeight([foundNum frame]))];
	
	return item;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
	 itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
	if([itemIdentifier isEqualToString:BSSToolbarSearchFieldItemIdentifier]) {
		return [self serachFieldItem];
	} else if([itemIdentifier isEqualToString:BSSToolbarSpinItemIdentifier]) {
		return [self spinItem];
	} else if([itemIdentifier isEqualToString:BSSToolbarFoundNumItemIdentifier]) {
		return [self foundNumItem];
	}
	
	return nil;
}
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	if(foundNum) {
		return [NSArray arrayWithObjects:BSSToolbarFoundNumItemIdentifier, BSSToolbarSearchFieldItemIdentifier, BSSToolbarSpinItemIdentifier, nil];
	} else {
		return [NSArray arrayWithObjects:BSSToolbarSearchFieldItemIdentifier, BSSToolbarSpinItemIdentifier, nil];
	}
}
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:BSSToolbarFoundNumItemIdentifier, BSSToolbarSearchFieldItemIdentifier, BSSToolbarSpinItemIdentifier, nil];
}

@end
