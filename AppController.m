
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Project:   The Cheat
//
// File:      AppController.m
// Created:   Wed Aug 13 2003
//
// Copyright: 2003 Chaz McGarvey.  All rights reserved.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#import "AppController.h"

#include "cheat_shared.h"

#import "AboutBoxController.h"
#import "PreferenceController.h"
#import "NetTrafficController.h"

#import "CheatListener.h"
#import "CheatServer.h"

#import "ServerHolder.h"


@implementation AppController

+ (void)initialize
{
	NSMutableDictionary		*defaults = [NSMutableDictionary dictionary];
	char					temp[104];
	
	// change the socket path to reside in the home directory of the current user
	strncpy( temp, [NSHomeDirectory() lossyCString], 103 );
	strncat( temp, TCDefaultListenPath, 103 - strlen(TCDefaultListenPath) );
	strncpy( TCDefaultListenPath, temp, 103 );

	[defaults setObject:[NSNumber numberWithBool:TCGlobalPlaySounds] forKey:TCPlaySoundsPref];
	[defaults setObject:[NSNumber numberWithBool:TCGlobalWindowsOnTop] forKey:TCWindowsOnTopPref];
	[defaults setObject:[NSNumber numberWithBool:TCGlobalAllowRemote] forKey:TCAllowRemotePref];
	[defaults setObject:[NSNumber numberWithInt:TCGlobalListenPort] forKey:TCListenPortPref];
	[defaults setObject:[NSString stringWithFormat:@"%@'s Computer", NSFullUserName()] forKey:TCBroadcastNamePref];

	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

	TCGlobalPlaySounds = [[NSUserDefaults standardUserDefaults] integerForKey:TCPlaySoundsPref];
	TCGlobalWindowsOnTop = [[NSUserDefaults standardUserDefaults] integerForKey:TCWindowsOnTopPref];
	TCGlobalListenPort = [[NSUserDefaults standardUserDefaults] integerForKey:TCListenPortPref];
	TCGlobalAllowRemote = [[NSUserDefaults standardUserDefaults] boolForKey:TCAllowRemotePref];
}

- (id)init
{
	if ( self = [super init] )
	{
		servers = [[NSMutableArray alloc] init];

		[self listenOnPort:TCGlobalListenPort remote:TCGlobalAllowRemote];
		[self broadcastWithName:TCGlobalBroadcastName];
		
		// set up the network browser
		browser = [[NSNetServiceBrowser alloc] init];
		[browser setDelegate:self];
		[browser searchForServicesOfType:@"_cheat._tcp." inDomain:@"local."];
		
		serverList = [[NSMutableArray alloc] init];
		
		[self setDelegate:self];
	}

	return self;
}


- (void)listenOnPort:(int)port remote:(BOOL)remote
{
	if ( connection )
	{
		[self stopListener];

		waitingToListen = YES;
		connectionPort = port;
		connectionRemote = remote;
	}
	else
	{
		connection = [[CheatListener listenerWithDelegate:self port:port remote:remote] retain];
		connectionPort = port;
		connectionRemote = remote;
	}
}

- (void)stopListener
{
	if ( connection )
	{
		close( sockfd );
		[connection release], connection = nil;
	}
}


- (void)broadcastWithName:(NSString *)name
{
	if ( TCGlobalAllowRemote )
	{
		[self stopBroadcast];
		
		service = [[NSNetService alloc] initWithDomain:@"local." type:@"_cheat._tcp." name:name port:TCGlobalListenPort];
		[service setDelegate:self];
		[service publish];
	}
}

- (void)stopBroadcast
{
	[service stop], service = nil;
}


- (IBAction)showAboutBoxWindow:(id)sender
{
	if ( !aboutBoxController )
	{
		aboutBoxController = [[AboutBoxController alloc] init];
	}
	
	[aboutBoxController showWindow:self];
}

- (IBAction)showPreferenceWindow:(id)sender
{
	if ( !preferenceController )
	{
		preferenceController = [[PreferenceController alloc] initWithDelegate:self];
	}

	[preferenceController showWindow:self];
}

- (IBAction)showNetTrafficWindow:(id)sender
{
	if ( !netTrafficController )
	{
		netTrafficController = [[NetTrafficController alloc] initWithDelegate:self];
	}

	[netTrafficController showWindow:self];
}


- (IBAction)launchHelpFile:(id)sender
{
	//[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"Read Me" ofType:@"html"] withApplication:@"Safari"];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Read Me" ofType:@"pdf"]]];
}

- (IBAction)launchWebsiteMenu:(id)sender
{
	LaunchWebsite();
}


- (NSArray *)serverList
{
	return serverList;
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[self stopListener];
	[self stopBroadcast];

	[servers release];
	
	[browser release];
	[serverList release];

	[super dealloc];
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%   PreferenceControlling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (void)preferenceAllowRemoteChanged:(BOOL)allow
{
	[self listenOnPort:TCGlobalListenPort remote:allow];
	
	if ( allow )
	{
		[self broadcastWithName:TCGlobalBroadcastName];
	}
	else
	{
		[self stopBroadcast];
	}

	[netTrafficController allowRemoteChanged:allow];
}

- (void)preferenceListenPortChanged:(int)port
{
	[self listenOnPort:port remote:TCGlobalAllowRemote];
	[self broadcastWithName:TCGlobalBroadcastName];

	[netTrafficController listenPortChanged:port];
}

- (void)preferenceBroadcastNameChanged:(NSString *)name
{
	[self broadcastWithName:name];

	[netTrafficController broadcastNameChanged:name];
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%   NetTrafficControlling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (int)netTrafficConnectionCount
{
	return [servers count];
}

- (NSArray *)netTrafficConnectionList
{
	return servers;
}

- (void)netTrafficKillConnection:(int)index
{
	NSLog( @"kill connection" );

	close( [[servers objectAtIndex:index] sockfd] );
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%   ListenerDelegate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (void)listenerListeningWithSocket:(int)sock
{
	sockfd = sock;

	TCGlobalListening = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"TCListenerStarted" object:nil];
}

- (void)listenerDisconnected
{
	if ( waitingToListen )
	{
		waitingToListen = NO;
		connection = [[CheatListener listenerWithDelegate:self port:connectionPort remote:connectionRemote] retain];
	}
	else
	{
		[self stopListener];
	}

	TCGlobalListening = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"TCListenerStopped" object:nil];
}

- (void)listenerError:(NSString *)error message:(NSString *)message
{
	NSRunCriticalAlertPanel( error, message, @"OK", nil, nil );
}

- (void)listenerReceivedNewConnection:(int)sock
{
	[servers addObject:[ServerHolder holderWithConnection:[CheatServer serverWithDelegate:self socket:sock] socket:sock]];
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%   ServerDelegate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (void)server:(CheatServer *)server connectedWithSocket:(int)sock
{
	int				i, top = [servers count];

	for ( i = 0; i < top; i++ )
	{
		if ( [(ServerHolder *)[servers objectAtIndex:i] sockfd] == sock )
		{
			[(ServerHolder *)[servers objectAtIndex:i] setServer:server];
			break;
		}
	}

	[netTrafficController connectionListChanged];
}

- (void)serverDisconnected:(CheatServer *)server
{
	int				i, top = [servers count];

	for ( i = 0; i < top; i++ )
	{
		if ( [(ServerHolder *)[servers objectAtIndex:i] server] == server )
		{
			[servers removeObjectAtIndex:i];
			break;
		}
	}

	[netTrafficController connectionListChanged];
}

- (void)server:(CheatServer *)server changedAddress:(NSString *)address
{
	int				i, top = [servers count];

	for ( i = 0; i < top; i++ )
	{
		if ( [(ServerHolder *)[servers objectAtIndex:i] server] == server )
		{
			[(ServerHolder *)[servers objectAtIndex:i] setAddress:address];
			break;
		}
	}

	[netTrafficController connectionListChanged];
}

- (void)server:(CheatServer *)server changedAction:(NSString *)action
{
	int				i, top = [servers count];

	for ( i = 0; i < top; i++ )
	{
		if ( [(ServerHolder *)[servers objectAtIndex:i] server] == server )
		{
			[(ServerHolder *)[servers objectAtIndex:i] setAction:action];
			break;
		}
	}

	[netTrafficController connectionListChanged];
}

- (NSArray *)serverProcessList
{
	return [[NSWorkspace sharedWorkspace] launchedApplications];
}

- (pid_t)serverFirstProcess
{
	return (pid_t)[[[[[NSWorkspace sharedWorkspace] launchedApplications] objectAtIndex:0] objectForKey:@"NSApplicationProcessIdentifier"] intValue];
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%   NetService Delegate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (void)netServiceWillPublish:(NSNetService *)sender
{
	NSLog( @"service will publish" );
	[sender resolve];
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
	NSLog( @"service did not publish" );
	
	if ( [[errorDict objectForKey:@"NSNetServicesErrorCode"] intValue] == NSNetServicesCollisionError )
	{
		[self broadcastWithName:[NSString stringWithFormat:@"%@ %i", TCGlobalBroadcastName, TCGlobalAlternateBroadcastNameCount++]];
	}
	else
	{
		NSRunCriticalAlertPanel( @"Network Error", @"Server couldn't broadcast.  Local can't be cheated by remote computers.", @"OK", nil, nil );
	}
}

- (void)netServiceDidStop:(NSNetService *)sender
{
	NSLog( @"service stopped" );
	[sender release];
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%   NSNetServiceBrowser Delegate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)aService moreComing:(BOOL)more
{
	// a server has broadcast; not much use until it's resolved.
	[aService setDelegate:self];
	[aService resolve];
}

- (void)netServiceDidResolveAddress:(NSNetService *)aService
{	
	int					i, top = [serverList count];
	
	// ignore if this is the local server.
	if ( TCGlobalAllowRemote && [[aService name] isEqualToString:TCGlobalBroadcastName] )
	{
		return;
	}
	
	// ignore if the server name is already in the list.
	for ( i = 0; i < top; i++ )
	{
		if ( [[aService name] isEqualToString:[(NSNetService *)[serverList objectAtIndex:i] name]] )
		{
			return;
		}
	}
	
	[serverList addObject:aService];
	NSLog( @"server added: %i", [serverList count] );
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"TCServerFound" object:aService];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)aService moreComing:(BOOL)more
{
	int					i, top = [serverList count];
	
	for ( i = 0; i < top; i++ )
	{
		if ( [[aService name] isEqualToString:[(NSNetService *)[serverList objectAtIndex:i] name]] )
		{
			[serverList removeObjectAtIndex:i];
			NSLog( @"server deleted: %i", [serverList count] );
			break;
		}
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"TCServerLost" object:aService];
}


@end