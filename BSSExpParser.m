//
//  BSSExpParser.m
//  BSSpotlighter
//
//  Created by Hori,Masaki on 06/05/16.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "BSSExpParser.h"

static BSSExpParser *sharedInstance = nil;

@implementation BSSExpParser

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

- (NSCharacterSet *)openParenthesisSet
{
	static id result = nil;

	if(!result) {
		@synchronized(self) {
			if(!result) {
				NSString *chars = [NSString stringWithFormat:@"%c%C", '(', 0xFF08];
				
				result = [[NSMutableCharacterSet alloc] init];
				[result addCharactersInString:chars];
			}
		}
	}

	return result;
}
- (NSCharacterSet *)closeParenthesisSet
{
	static id result = nil;
	
	if(!result) {
		@synchronized(self) {
			if(!result) {
				NSString *chars = [NSString stringWithFormat:@"%c%C", ')', 0xFF09];
				
				result = [[NSMutableCharacterSet alloc] init];
				[result addCharactersInString:chars];
			}
		}
	}
	
	return result;
}
- (NSCharacterSet *)orSet
{
	static id result = nil;
	
	if(!result) {
		@synchronized(self) {
			if(!result) {
				NSString *chars = [NSString stringWithFormat:@"%c%C", '|', 0xFF5C];
				
				result = [[NSMutableCharacterSet alloc] init];
				[result addCharactersInString:chars];
			}
		}
	}
	
	return result;
}
- (NSCharacterSet *)andSet
{
	static id result = nil;
	
	if(!result) {
		@synchronized(self) {
			if(!result) {
				NSString *chars = [NSString stringWithFormat:@"%c%C", '&', 0xFF06];
				
				result = [[NSMutableCharacterSet alloc] init];
				[result addCharactersInString:chars];
			}
		}
	}
	
	return result;
}
- (NSCharacterSet *)notSet
{
	static id result = nil;
	
	if(!result) {
		@synchronized(self) {
			if(!result) {
				NSString *chars = [NSString stringWithFormat:@"%c%C", '!', 0xFF01];
				
				result = [[NSMutableCharacterSet alloc] init];
				[result addCharactersInString:chars];
			}
		}
	}
	
	return result;
}
- (NSString *)predicateStringForTokens:(BSSTokenizer *)token forKey:(NSString *)key
{
	NSMutableString *result = [NSMutableString string];
	
	NSCharacterSet *openParenthesisSet = [self openParenthesisSet];
	NSCharacterSet *closeParenthesisSet = [self closeParenthesisSet];
	NSCharacterSet *orSet = [self orSet];
	NSCharacterSet *andSet = [self andSet];
	NSCharacterSet *notSet = [self notSet];
	
	BOOL isFirst = YES;
	NSString *andOrStr = @"";
	NSString *notStr = @"";
	
	NSString *str;
	
	while(str = [token nextToken]) {
		if([openParenthesisSet characterIsMember:[str characterAtIndex:0]]) {
			NSString *subPredicate;
			NSString *s;
			BOOL foundClose = NO;
			unsigned start, end;
			
			[token saveTokenIndex];
			start = [token currentIndex];
			while(s = [token nextToken]) {
				if([closeParenthesisSet characterIsMember:[s characterAtIndex:0]]) {
					NSRange range;
					foundClose = YES;
					end = [token currentIndex];
					range = NSMakeRange(start, end - start - 1);
					BSSTokenizer *sub = [token tokenizerWithRange:range];
					subPredicate = [self predicateStringForTokens:sub forKey:key];
					
					break;
				}
			}
			if(foundClose) {
				[result appendFormat:@"%@%@(%@)", andOrStr, notStr, subPredicate];
//				[token rewind];
				isFirst = NO;
			} else {
				[token restoreTokenIndex];
				continue;
			}
			
		} else if([orSet characterIsMember:[str characterAtIndex:0]]) {
			andOrStr = isFirst ? @"" : @" || ";
			continue;
		} else if([andSet characterIsMember:[str characterAtIndex:0]]) {
			//
			continue;
		} else if([notSet characterIsMember:[str characterAtIndex:0]]) {
			notStr = @" NOT ";
			continue;
		} else {
			[result appendFormat:@"%@%@(%@ LIKE[cw] '*%@*')", andOrStr, notStr, key, str];
			isFirst = NO;
		}
		
		andOrStr = isFirst ? @"" : @" && ";
		notStr = @"";
	}
	
	return result;
}

@end

@implementation BSSTokenizer

+ (id)tokenizerWithString:(NSString *)string
{
	return [[[[self class] alloc] initWithString:string] autorelease];
}

- (id)initWithString:(NSString *)string
{
	if(self = [super init]) {
		mTokens = [[[self class] tokensFromString:string] retain];
		mCurrentIndex = mSavedIndex = 0;
	}
	
	return self;
}

- (id)initWithTokens:(NSArray *)array
{
	if(self = [super init]) {
		mTokens = [NSArray arrayWithArray:array];
		mCurrentIndex = mSavedIndex = 0;
	}
	
	return self;
}

- (NSString *)currentToken
{
	id res;
	
	if(mCurrentIndex == UINT_MAX) return nil;
	
	@try {
		res = [mTokens objectAtIndex:mCurrentIndex];
	}
	@catch(NSException *ex) {
		if([[ex name] isEqualToString:NSRangeException]) {
			res = nil;
		} else {
			[ex raise];
		}
	}
	
	return res;
}
// return nil, if not have next token.
- (NSString *)nextToken
{
	id res = [self currentToken];
	
	mCurrentIndex++;
	
	return res;
}
- (BOOL)hasNextToken
{
	return [self count] <= mCurrentIndex + 1 ? NO : YES;
}

- (unsigned)count
{
	return [mTokens count];
}
- (unsigned)currentIndex
{
	return mCurrentIndex;
}

- (BSSTokenizer *)tokenizerWithRange:(NSRange)range
{
	NSArray *tokens = [mTokens subarrayWithRange:range];
	
	return [[[[self class] allocWithZone:[self zone]] initWithTokens:tokens] autorelease];
}

- (void)saveTokenIndex
{
	mSavedIndex = mCurrentIndex;
}
- (void)restoreTokenIndex
{
	mCurrentIndex = mSavedIndex;
}
- (void)rewind
{
	mCurrentIndex--;
}

+ (NSCharacterSet *)tokenCharacterSet
{
	static id result = nil;
	
	if(!result) {
		@synchronized(self) {
			if(!result) {
				NSString *path;
				NSString *chars;
				
				path = [[NSBundle bundleForClass:[self class]] pathForResource:@"tokenCharacter"
																		ofType:@"txt"];
				chars = [NSString stringWithContentsOfFile:path
												  encoding:NSUTF8StringEncoding
													 error:NULL];
				
				result = [[NSMutableCharacterSet alloc] init];
				[result addCharactersInString:chars];
			}
		}
	}
	
	return result;
	
}
+ (NSArray *)tokensFromString:(NSString *)string
{
	NSMutableArray *result = [NSMutableArray array];
	
	NSCharacterSet *tokenCharacterSet = [self tokenCharacterSet];
	NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	unsigned idx, mark, length;
	unichar uchar;
	
	idx = mark = 0;
	length = [string length];
	
	for(idx = 0; idx < length; idx++) {
		NSString *substr;
		
		uchar = [string characterAtIndex:idx];
		if([tokenCharacterSet characterIsMember:uchar]) {
			if(mark != idx) {
				substr = [string substringWithRange:NSMakeRange(mark, idx - mark)];
				[result addObject:substr];
				mark = idx;
			}
			substr = [string substringWithRange:NSMakeRange(mark, idx - mark + 1)];
			[result addObject:substr];
			mark = idx + 1;
			continue;
		}
		if([whitespaceCharacterSet characterIsMember:uchar]) {
			if(mark != idx) {
				substr = [string substringWithRange:NSMakeRange(mark, idx - mark)];
				[result addObject:substr];
			}
			mark = idx + 1;
			continue;
		}
		if(idx == length - 1) {
			substr = [string substringWithRange:NSMakeRange(mark, idx - mark + 1)];
			[result addObject:substr];
			//mark = idx + 1;
			//continue;
		}
	}
	
	return [NSArray arrayWithArray:result];
}

@end
