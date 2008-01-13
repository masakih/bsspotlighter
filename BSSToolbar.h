//
//  BSSToolbar.h
//  BSSpotlighter
//
//  Created by Hori,Masaki on 06/05/15.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BSSToolbar : NSObject
{
	IBOutlet id searchField;
	IBOutlet id spin;
	IBOutlet id foundNum;
}

+ (id)sharedInstance;

- (NSToolbar *)toolbar;
@end
