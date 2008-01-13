//
//  BSSExpParser.h
//  BSSpotlighter
//
//  Created by Hori,Masaki on 06/05/16.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BSSTokenizer;

@interface BSSExpParser : NSObject
{}

+ (id)sharedInstance;

- (NSString *)predicateStringForTokens:(BSSTokenizer *)token forKey:(NSString *)key;
@end


@interface BSSTokenizer : NSObject
{
	NSArray *mTokens;
	
	unsigned mCurrentIndex;
	unsigned mSavedIndex;
}


+ (id)tokenizerWithString:(NSString *)string;
- (id)initWithString:(NSString *)string;

+ (NSArray *)tokensFromString:(NSString *)string;

- (NSString *)currentToken;
- (NSString *)nextToken; // return nil, if not have next token.
- (BOOL)hasNextToken;

- (unsigned)count;
- (unsigned)currentIndex;

- (BSSTokenizer *)tokenizerWithRange:(NSRange)range;

- (void)saveTokenIndex;
- (void)restoreTokenIndex;

- (void)rewind;

@end