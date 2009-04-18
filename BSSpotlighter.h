/* BSSpotlighter */

#import <Cocoa/Cocoa.h>

@interface BSSpotlighter : NSObject
{
	IBOutlet id mWindow;
	IBOutlet id mTableView;
	IBOutlet id mSearchField;
	IBOutlet id mFoundListController;
	IBOutlet id mTableHeaderMenu;
	
	id mQuery;
	
	BOOL mInProgress;
	
	NSArray *mCurrentKeys;
}
- (IBAction)changePredicate:(id)sender;
- (IBAction)openSelections:(id)sender;
- (IBAction)showHideHeader:(id)sender;
- (IBAction)openInfomationInFinder:(id)sender;

- (void)openThread:(id)path;

- (id) metadataQuery;
- (void) setMatadataQuery: (id) newValue;
@end
