
/*
 * The Cheat - The legendary universal game trainer for Mac OS X.
 * http://www.brokenzipper.com/trac/wiki/TheCheat
 *
 * Copyright (c) 2003-2011, Charles McGarvey et al.
 *
 * Distributable under the terms and conditions of the 2-clause BSD
 * license; see the file COPYING for the legal text of the license.
 */


#import "ChazUpdate.h"


// an NSError that an have an error statement associated with it
@interface ChazUpdateError : NSError
{
	NSString *_errorString;
}
+ (id)errorWithString:(NSString *)string;
- (id)initWithString:(NSString *)string;
- (void)setErrorString:(NSString *)string;
- (NSString *)localizedDescription;
@end
@implementation ChazUpdateError
+ (id)errorWithString:(NSString *)string
{
	return [[[ChazUpdateError alloc] initWithString:string] autorelease];
}
- (id)initWithString:(NSString *)string
{
	if ( self = [super initWithDomain:@"ChazUpdateError" code:1 userInfo:nil] ) {
		[self setErrorString:string];
	}
	return self;
}
- (void)setErrorString:(NSString *)string
{
	[string retain];
	[_errorString release];
	_errorString = string;
}
- (NSString *)localizedDescription
{
	return _errorString;
}
@end


@interface ChazUpdate : NSObject
{
	NSString *_name;
	
	NSURLConnection *_connection;
	NSHTTPURLResponse *_response;
	NSMutableData *_responseData;
	
	BOOL _verbose;
}

- (id)initWithURL:(id)url name:(NSString *)name verbose:(BOOL)verbose;
- (void)kill;

@end


@implementation ChazUpdate


#pragma mark Initialization

- (id)initWithURL:(id)url name:(NSString *)name verbose:(BOOL)verbose
{
	NSURL *theURL;
	
	if ( self = [super init] )
	{
		// figure out what type of URL was passed
		if ( [url isKindOfClass:[NSURL class]] ) {
			theURL = url;
		}
		else if ( [url isKindOfClass:[NSString class]] ) {
			theURL = [[[NSURL alloc] initWithString:url] autorelease];
		}
		else {
			if ( verbose ) {
				NSRunAlertPanel( @"Update Check Failed",
								 @"Could not determine the location of the version information file.", @"OK", nil, nil );
			}
			[self release];
			return nil;
		}
		// save the name
		if ( name ) {
			_name = [name retain];
		}
		else {
			_name = [[NSString stringWithString:@""] retain];
		}
		_verbose = verbose;
		
		// create the request
		_connection = [[NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:theURL
																			   cachePolicy:NSURLRequestReloadIgnoringCacheData
																		   timeoutInterval:30.0] delegate:self] retain];
		_response = nil;
		_responseData = [[NSMutableData alloc] init];
	}
	return self;
}


- (void)dealloc
{
	// cleanup
	[_name release];
	
	[_connection release];
	[_response release];
	[_responseData release];
	
	[super dealloc];
}

- (void)kill
{
	[self release];
	self = nil;
}


#pragma mark NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	if ( _response ) {
		// another response, chop the data
		[_responseData setLength:0];
		[_response release];
	}
	_response = [response retain];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	// just save the data
	[_responseData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSDictionary *plistDictionary;
	NSPropertyListFormat plistFormat;
	NSString *plistError;
	
	NSDictionary *appDictionary;
	
	NSString *appRedirect;
	NSString *appVersion;
	NSString *appOnline;
	NSDate *appReleaseDate;
	NSString *appDownload;
	NSString *appDescription;
	
	// read in the recently downloaded plist
	plistDictionary = [NSPropertyListSerialization propertyListFromData:_responseData
													   mutabilityOption:NSPropertyListImmutable
																 format:&plistFormat
													   errorDescription:&plistError];
	if ( !plistDictionary ) {
		[self connection:connection didFailWithError:[ChazUpdateError errorWithString:plistError]];
		return;
	}
	// make sure the root object is a dictionary
	if ( ![NSStringFromClass([plistDictionary class]) isEqualToString:@"NSCFDictionary"] ) {
		[self connection:connection didFailWithError:[ChazUpdateError errorWithString:@"the version information file is ill-formatted"]];
		return;
	}
	appDictionary = [plistDictionary objectForKey:_name];
	if ( !appDictionary ) {
		[self connection:connection didFailWithError:[ChazUpdateError errorWithString:@"no version information for this application"]];
		return;
	}
	
	// see if the version information for this app is in another file
	if ( appRedirect = [appDictionary objectForKey:@"Redirect"] ) {
		// recursively follow the redirection
		[[ChazUpdate alloc] initWithURL:appRedirect name:_name verbose:_verbose];
		[self kill];
		return;
	}
	
	// read other useful information about the app
	appVersion = [appDictionary objectForKey:@"Version"];
	appReleaseDate = [NSDate dateWithNaturalLanguageString:[appDictionary objectForKey:@"ReleaseDate"]];
	appOnline = [appDictionary objectForKey:@"MoreInfoURL"];
	appDownload = [appDictionary objectForKey:@"DownloadURL"];
	appDescription = [appDictionary objectForKey:@"Description"];
	
	if ( !appReleaseDate ) {
		[self connection:connection didFailWithError:[ChazUpdateError errorWithString:@"missing version information"]];
		return;
	}
	
	if ( !appVersion ) {
		appVersion = @"";
	}
	
	if ( [ChazAppBuildDate() compare:appReleaseDate] == NSOrderedAscending ) {
		// there is a new version, display message
		int choice;
		
		NSString *desc;
		NSString *mainBtn;
		NSString *alternate;
		NSString *other;
		
		if ( appDescription ) {
			desc = appDescription;
		}
		else {
			desc = [NSString stringWithFormat:@"A new version of %@ is available!  Would you like to learn more about the new version now?", _name];
		}
		if ( appOnline ) {
			mainBtn = @"Learn More";
			other = @"Cancel";
		}
		else {
			mainBtn = @"OK";
			other = nil;
		}
		if ( appDownload ) {
			alternate = @"Download";
		}
		else {
			alternate = nil;
		}
		
		choice = NSRunInformationalAlertPanel( [NSString stringWithFormat:@"New Version: %@ %@", _name, appVersion],
											   desc, mainBtn, alternate, other );
		
		if ( choice == NSAlertDefaultReturn && appOnline ) {
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:appOnline]];
		}
		else if ( choice == NSAlertAlternateReturn ) {
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:appDownload]];
		}
	}
	else if ( _verbose ) {
		// alert that the user has the latest version if we're in verbose mode
		NSRunInformationalAlertPanel( [NSString stringWithFormat:@"%@ %@", _name, ChazAppVersion()],
									  @"You have the latest version of %@.", @"OK", nil, nil, _name );
	}
	
	[self kill];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if ( _verbose )
	{
		// check failed, display an error
		NSRunAlertPanel( @"Update Check Failed", @"Check could not get new version data.\nError code #%i (%@)", @"OK", nil, nil, [error code], [error localizedDescription] );
	}
	
	[self kill];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
	// handle http redirection
	return request;
}


@end


#pragma mark API Functions

void ChazCheckForUpdate( id url, BOOL userRequested )
{
	[[ChazUpdate alloc] initWithURL:url name:ChazAppName() verbose:userRequested];
}

void ChazCheckForUpdateWithName( id url, NSString *appName, BOOL userRequested )
{
	[[ChazUpdate alloc] initWithURL:url name:appName verbose:userRequested];
}


NSString *ChazAppName()
{
	NSString *name;
	
	name = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
	if ( name && ![name isEqualToString:@""] ) {
		return name;
	}
	name = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
	if ( name && ![name isEqualToString:@""] ) {
		return name;
	}
	return @"";
}

NSString *ChazAppVersion()
{
	NSString *vers;
	
	vers = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
	if ( vers && ![vers isEqualToString:@""] ) {
		return vers;
	}
	vers = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
	if ( vers && ![vers isEqualToString:@""] ) {
		return vers;
	}
	return @"";
}

NSDate *ChazAppBuildDate()
{
	return [NSDate dateWithNaturalLanguageString:[NSString stringWithFormat:@"%s %s", __TIME__, __DATE__]];
}

