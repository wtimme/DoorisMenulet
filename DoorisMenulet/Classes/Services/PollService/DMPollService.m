//
//  DMPollService.m
//  DoorisMenulet
//
//  Created by Wolfgang Timme on 06/11/13.
//  Copyright (c) 2013 Wolfgang Timme. All rights reserved.
//

#import "DMPollService.h"

#define DEBUG_POLL_SERVICE 0

@interface DMPollService ()
{
    NSTimer *_updateTimer;
    NSHashTable *_observers;
    
    DMPollServiceDoorState _doorState;
}

/**
 * @return Objects that observe this service' state.
 */
- (NSHashTable *)observers;

/**
 * @details Notifies the observers that the status is being updated.
 */
- (void)notifyObserversUpdatingDoorStatus;

/**
 * @details Notifies the observers that the door has opened.
 */
- (void)notifyObserversDoorDidOpen;

/**
 * @details Notifies the observers taht the door has closed.
 */
- (void)notifyObserversDoorDidClose;

/**
 * @return The timer that triggers the update.
 */
- (NSTimer *)updateTimer;

/**
 * @details Schedules the update timer.
 */
- (void)scheduleUpdateTimer;

/**
 * @details Updates the status by polling the newest data from remote.
 */
- (void)fetchDoorState;

/**
 * @return The current state of the door.
 */
- (DMPollServiceDoorState)doorState;

/**
 * @details Sets the state of the door.
 * @param doorState The state of the door.
 */
- (void)setDoorState:(DMPollServiceDoorState)doorState;

/**
 * @details Updates the service with the door state provided.
 * @param doorState The door state to update the service with.
 */
- (void)updateWithDoorState:(DMPollServiceDoorState)doorState;

/**
 * @details Logs a debug message to NSLog and prepends the class name.
 * @param debugMessage The debug message to log.
 */
- (void)debugWithClassNamePrepended:(NSString *)debugMessage;

@end

@implementation DMPollService

static NSString *kPollingUrl = @"http://www.hamburg.ccc.de/dooris/json.php";
static NSTimeInterval kPollingInterval = 10.0f;

static NSString *kDoorJsonKey = @"door";
static NSString *kStatusJsonKey = @"status";

static DMPollService *_sharedInstance;

+ (DMPollService *)sharedInstance
{
    if (!_sharedInstance)
    {
        _sharedInstance = [[DMPollService alloc] init];
    }
    
    return _sharedInstance;
}

- (id)init
{
    if (self = [super init])
    {
        _doorState = DMPollServiceDoorStateUnknown;
    }
    
    return self;
}

#pragma mark - Observers

- (NSHashTable *)observers
{
    if (!_observers)
    {
        _observers = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    
    return _observers;
}

- (void)addObserver:(id<DMPollServiceObserver>)observer
{
    [[self observers] addObject:observer];
}

- (void)removeObserver:(id<DMPollServiceObserver>)observer
{
    [[self observers] removeObject:observer];
}

- (void)notifyObserversUpdatingDoorStatus
{
    for (id<DMPollServiceObserver>observer in [[self observers] allObjects])
    {
        if ([observer respondsToSelector:@selector(pollServiceIsUpdatingStatus:)])
        {
            [observer pollServiceIsUpdatingStatus:self];
        }
    }
}

- (void)notifyObserversDoorDidOpen
{
    for (id<DMPollServiceObserver>observer in [[self observers] allObjects])
    {
        if ([observer respondsToSelector:@selector(doorDidOpen)])
        {
            [observer doorDidOpen];
        }
    }
}

- (void)notifyObserversDoorDidClose
{
    for (id<DMPollServiceObserver>observer in [[self observers] allObjects])
    {
        if ([observer respondsToSelector:@selector(doorDidClose)])
        {
            [observer doorDidClose];
        }
    }
}

- (void)startWatchingStatus
{
    [self fetchDoorState];
}

- (void)stopWatchingStatus
{
    [[self updateTimer] invalidate];
    _updateTimer = nil;
}

#pragma mark - Update Timer

- (NSTimer *)updateTimer
{
    return _updateTimer;
}

- (void)scheduleUpdateTimer
{
    // Only schedule timer if not already done.
    if (![self updateTimer] || ![[self updateTimer] isValid])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            _updateTimer = [NSTimer scheduledTimerWithTimeInterval:kPollingInterval
                                                            target:self
                                                          selector:@selector(fetchDoorState)
                                                          userInfo:nil
                                                           repeats:NO];
        });
    }
}

#pragma mark - Status

- (void)doorStatusWithSuccessHandler:(void (^)(DMPollServiceDoorState doorState))successHandler
                        errorHandler:(void (^)(NSError *error))errorHandler
{
    NSURL *url = [NSURL URLWithString:kPollingUrl];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:urlRequest
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         if (!error)
         {
             // Parse JSON.
             NSError *jsonParsingError;
             NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParsingError];
             
             if (!jsonParsingError)
             {
                 DMPollServiceDoorState doorState = DMPollServiceDoorStateUnknown;
                 
                 NSDictionary *doorData = [json objectForKey:kDoorJsonKey];
                 if (doorData)
                 {
                     id doorStateReceived = [doorData objectForKey:kStatusJsonKey];
                     if (doorStateReceived)
                     {
                         NSUInteger doorStatusCode = [doorStateReceived integerValue];
                         if (0 == doorStatusCode)
                         {
                             doorState = DMPollServiceDoorStateOpen;
                         }
                         else if (1 == doorStatusCode)
                         {
                             doorState = DMPollServiceDoorStateClosed;
                         }
                     }
                 }
                 
                 successHandler(doorState);
             }
             else
             {
                 errorHandler(jsonParsingError);
             }
         }
         else
         {
             errorHandler(error);
         }
     }];
}

- (void)fetchDoorState
{
    [self debugWithClassNamePrepended:@"Updating door state..."];
    
    [self setDoorState:DMPollServiceDoorStateUnknown];
    [self notifyObserversUpdatingDoorStatus];
    
    [self doorStatusWithSuccessHandler:^(DMPollServiceDoorState doorState) {
        [self updateWithDoorState:doorState];
        
        [self scheduleUpdateTimer];
    } errorHandler:^(NSError *error) {
        [self debugWithClassNamePrepended:@"Error while trying to update door state."];
        
        [self updateWithDoorState:DMPollServiceDoorStateUnknown];
    }];
}

- (DMPollServiceDoorState)doorState
{
    return _doorState;
}

- (void)setDoorState:(DMPollServiceDoorState)doorState
{
    _doorState = doorState;
}

- (void)updateWithDoorState:(DMPollServiceDoorState)doorState
{
    if (DMPollServiceDoorStateOpen == doorState && DMPollServiceDoorStateOpen != [self doorState])
    {
        // The door is now open.
        [self debugWithClassNamePrepended:@"The door is open now."];
        
        [self notifyObserversDoorDidOpen];
    }
    else if (DMPollServiceDoorStateClosed == doorState && DMPollServiceDoorStateClosed != [self doorState])
    {
        // The door is closed now.
        [self debugWithClassNamePrepended:@"The door is closed now."];
        
        [self notifyObserversDoorDidClose];
    }
    else
    {
        [self debugWithClassNamePrepended:@"Door state unknown or unchanged."];
    }
    
    // Store the new state.
    [self setDoorState:doorState];
}

#pragma mark - Debugging

- (void)debugWithClassNamePrepended:(NSString *)debugMessage
{
    if (DEBUG_POLL_SERVICE)
    {
        NSLog(@"%@: %@", NSStringFromClass([self class]), debugMessage);
    }
}

@end
