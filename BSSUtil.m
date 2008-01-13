/*
 *  BSSUtil.c
 *  BSSpotlighter
 *
 *  Created by Hori,Masaki on 06/12/16.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#import "BSSUtil.h"
#import "stdarg.h"

#import <Foundation/Foundation.h>
#import "NSAppleEventDescriptor-Extensions.h"


#import <AppKit/NSWorkspace.h>

NSString *BSSLogForceWrite = @"BSSLogForceWrite";

void BSSLog(NSString *format, ...)
{
	va_list ap;
	
	va_start(ap, format);
	BSSLogv(format, ap);
	va_end(ap);
}

#ifdef DEBUG
void BSSLogv(NSString *format, va_list args)
{
	NSLogv(format, args);
}
#else
void BSSLogv(NSString *format, va_list args)
{
	NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
	if([def boolForKey:BSSLogForceWrite]) {
		NSLogv(format, args);
	}
}
#endif

OSStatus activateFinderOnlyFrontWindow()
{
	[[NSWorkspace sharedWorkspace] launchApplication:@"Finder"];
	return noErr;
}
OSStatus openInfomationInFinderWithPath(NSString *filePath)
{
	NSAppleEventDescriptor *ae;
	NSAppleEventDescriptor *targetDesc;
	NSAppleEventDescriptor *fileInfoDesc;
	OSStatus err;
	
	targetDesc = [NSAppleEventDescriptor targetDescriptorWithAppName:@"Finder"];
	if(!targetDesc) {
		BSSLog(@"Can NOT create targetDesc.");
		return kBSSUtilCanNotCreateTragetDescErr;
	}
	
	ae = [NSAppleEventDescriptor appleEventWithEventClass:kCoreEventClass
												  eventID:kAEOpenDocuments
										 targetDescriptor:targetDesc
												 returnID:kAutoGenerateReturnID
											transactionID:kAnyTransactionID];
	{
		NSAppleEventDescriptor *fileDesc;
		NSAppleEventDescriptor *fileNameDesc;
		NSURL *fileURL = [NSURL fileURLWithPath:filePath];
		const char *fileURLCharP;
		
		fileURLCharP = [[fileURL absoluteString] fileSystemRepresentation];
		fileNameDesc = [NSAppleEventDescriptor descriptorWithDescriptorType:typeFileURL
																	  bytes:fileURLCharP
																	 length:strlen(fileURLCharP)];
		
		fileDesc = [NSAppleEventDescriptor objectSpecifierWithDesiredClass:cFile
																 container:nil
																   keyForm:formName
																   keyData:fileNameDesc];
		fileInfoDesc = [NSAppleEventDescriptor
							objectSpecifierWithDesiredClass:cProperty
												  container:fileDesc
													keyForm:cProperty
													keyData:[NSAppleEventDescriptor descriptorWithTypeCode:cInfoWindow]];
		
		[ae setParamDescriptor:fileInfoDesc
					forKeyword:keyDirectObject];
	}
	if(!ae) {
		BSSLog(@"Can NOT create AppleEvent.");
		return kBSSUtilCanNotCreateAppleEventErr;
	}
	
	@try {
		err = [ae sendAppleEventWithMode:kAENoReply | kAENeverInteract
						  timeOutInTicks:kAEDefaultTimeout
								  replay:NULL];
	}
	@catch (NSException *ex) {
		if(![[ex name] isEqualTo:HMAEDescriptorSendingNotAppleEventException]) {
			@throw;
		}
	}
	@finally {
		if( err != noErr ) {
			BSSLog(@"AESendMessage Error. Error NO is %d.", err );
		}
	}
	
	return activateFinderOnlyFrontWindow();
}
