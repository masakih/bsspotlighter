//
//  BSSTableView.m
//  BSSpotlighter
//
//  Created by Hori,Masaki on 07/01/13.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "BSSTableView.h"


@implementation BSSTableView
- (void)awakeFromNib
{
	[self setVerticalMotionCanBeginDrag:NO];
}
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag
{
	return NSDragOperationCopy;
}

- (void)rightMouseDown:(NSEvent *)event
{
	// multi rows selected.
	if([self numberOfSelectedRows] > 1) {
		[super rightMouseDown:event];
		return;
	}
	
	NSPoint mouse = [self convertPoint:[event locationInWindow] fromView:nil];
	
	int row = [self rowAtPoint:mouse];
	
	[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row]
	  byExtendingSelection:NO];
	
	[super rightMouseDown:event];
}
@end
