//
//  DMPollServiceObserverProtocol.h
//  DoorisMenulet
//
//  Created by Wolfgang Timme on 06/11/13.
//  Copyright (c) 2013 Wolfgang Timme. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DMPollServiceObserver <NSObject>

@optional

/**
 * @details Is called when the poll service is updating the status.
 * @param pollService The poll service that is updating the status.
 */
- (void)pollServiceIsUpdatingStatus:(id)pollService;

/**
 * @details Is called when the door has been opened.
 */
- (void)doorDidOpen;

/**
 * @details Is called when the door has been closed.
 */
- (void)doorDidClose;

@end
