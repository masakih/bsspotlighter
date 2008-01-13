//
//  BSSArrayController.m
//  BSSpotlighter
//
//  Created by Hori,Masaki on 07/01/13.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "BSSArrayController.h"


@implementation BSSArrayController

 - (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
	NSArray *dragedObjects = [self arrangedObjects];
	NSEnumerator *dragedEnum;
	id obj;
	NSMutableArray *filenames = [NSMutableArray array];
	BOOL result = NO;
	
	[pboard declareTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, NSStringPboardType, NSURLPboardType, nil]
				   owner:self];
	
	dragedObjects = [dragedObjects objectsAtIndexes:rowIndexes];
	dragedEnum = [dragedObjects objectEnumerator];
	while(obj = [dragedEnum nextObject]) {
		id value = [obj valueForAttribute:(NSString *)kMDItemPath];
		
		[filenames addObject:value];
		[pboard setString:value forType:NSStringPboardType];
		id url = [NSURL fileURLWithPath:value];
		if(url) {
			[url writeToPasteboard:pboard];
		}
	}
	if([filenames count] != 0) {
		result = [pboard setPropertyList:filenames forType:NSFilenamesPboardType];
	}
	
	return result;
}

@end
