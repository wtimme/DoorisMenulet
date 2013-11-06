//
//  DMAppDelegate.m
//  DoorisMenulet
//
//  Created by Wolfgang Timme on 06/11/13.
//  Copyright (c) 2013 Wolfgang Timme. All rights reserved.
//

#import "DMAppDelegate.h"

#import "DMPollService.h"

@interface DMAppDelegate ()
{
    NSStatusItem *_statusItem;
}

/**
 * @return The status item that is visible in the menu bar.
 */
- (NSStatusItem *)statusItem;

/**
 * @details Sets up the status item visible in the menu bar.
 */
- (void)setupStatusItem;

/**
 * @details Updates the status item with the parameters provided.
 * @param title The title.
 * @param toolTip The tool tip.
 */
- (void)updateStatusItemWithTitle:(NSString *)title
                          toolTip:(NSString *)toolTip;

/**
 * @details Updates the status item for when the poll service is updating the status.
 */
- (void)updateStatusItemForUpdating;

@end

@implementation DMAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (void)awakeFromNib
{
    [self setupStatusItem];
    
    [[DMPollService sharedInstance] addObserver:self];
    [[DMPollService sharedInstance] startWatchingStatus];
}

#pragma mark - Status Item

- (NSStatusItem *)statusItem
{
    if (!_statusItem)
    {
        _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    }
    
    return _statusItem;
}

- (void)setupStatusItem
{
    [[self statusItem] setHighlightMode:YES];
    [[self statusItem] setTitle:@"Status: ..."];
    [[self statusItem] setEnabled:NO];
    [[self statusItem] setToolTip:@"Fetching current door status..."];
}

- (void)updateStatusItemWithTitle:(NSString *)title
                          toolTip:(NSString *)toolTip
{
    NSString *fullTitle = [NSString stringWithFormat:@"Door: %@", title];
    [[self statusItem] setTitle:fullTitle];
    
    NSString *fullToolTip = [NSString stringWithFormat:@"Dooris: %@", toolTip];
    [[self statusItem] setToolTip:fullToolTip];
}

- (void)updateStatusItemForUpdating
{
    [self updateStatusItemWithTitle:@"..."
                            toolTip:@"Checking server for updates."];
}

#pragma mark - DMPollServiceObserver methods

- (void)pollServiceIsUpdatingStatus:(id)pollService
{
    [self updateStatusItemForUpdating];
}

- (void)doorDidOpen
{
    [self updateStatusItemWithTitle:@"✔"
                            toolTip:@"The door is open at the moment."];
}

- (void)doorDidClose
{
    [self updateStatusItemWithTitle:@"✖"
                            toolTip:@"The door is closed at the moment."];
}

@end
