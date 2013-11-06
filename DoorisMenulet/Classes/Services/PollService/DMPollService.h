//
//  DMPollService.h
//  DoorisMenulet
//
//  Created by Wolfgang Timme on 06/11/13.
//  Copyright (c) 2013 Wolfgang Timme. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DMPollServiceObserverProtocol.h"

typedef enum DMPollServiceDoorStates
{
    DMPollServiceDoorStateUnknown = 1,
    DMPollServiceDoorStateOpen,
    DMPollServiceDoorStateClosed
} DMPollServiceDoorState;

@interface DMPollService : NSObject

/**
 * @return A single shared instance of this object.
 */
+ (DMPollService *)sharedInstance;

/**
 * @details Starts periodically updating the status.
 */
- (void)startWatchingStatus;

/**
 * @details Stops updating the status.
 */
- (void)stopWatchingStatus;

/**
 * @details Gets the current status of the door.
 * @param successHandler Block that is executed once the status has been determined.
 * @param errorHandler Block that is executed in case of an error.
 */
- (void)doorStatusWithSuccessHandler:(void (^)(DMPollServiceDoorState doorState))successHandler
                        errorHandler:(void (^)(NSError *error))errorHandler;

/**
 * @details Adds an observer to this service.
 * @param observer An object that listens for changes of this service.
 */
- (void)addObserver:(id<DMPollServiceObserver>)observer;

/**
 * @details Removes an observer from this service.
 * @param observer An object that listens for changes of this service.
 */
- (void)removeObserver:(id<DMPollServiceObserver>)observer;


@end
