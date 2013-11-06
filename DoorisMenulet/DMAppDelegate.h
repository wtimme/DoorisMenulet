//
//  DMAppDelegate.h
//  DoorisMenulet
//
//  Created by Wolfgang Timme on 06/11/13.
//  Copyright (c) 2013 Wolfgang Timme. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "DMPollServiceObserverProtocol.h"

@interface DMAppDelegate : NSObject <NSApplicationDelegate, DMPollServiceObserver>

@property (assign) IBOutlet NSWindow *window;

@end
