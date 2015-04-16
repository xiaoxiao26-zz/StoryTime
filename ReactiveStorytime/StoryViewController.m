//
//  ViewController.m
//  ReactiveStorytime
//
//  Created by Alex Xiao on 3/7/15.
//  Copyright (c) 2015 Stever2Startup. All rights reserved.
//

#import "StoryViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <AFNetworking-RACExtensions/RACAFNetworking.h>
#import "StoryManager.h"
#import "LocationManager.h"

@interface StoryViewController ()

@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) RACCommand *timerCommand;

@property (strong, nonatomic) RACCommand *fetchFirstStoryCommand;
@property (strong, nonatomic) RACCommand *fetchNextStoryCommand;


@end

@implementation StoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Storytime";
    self.timerLabel.text = @"";
    
    [self setUpCommands];
    [self bindUI];
}

- (void)setUpCommands {
    
    RACSignal *done = [self.doneButton rac_signalForControlEvents:UIControlEventTouchUpInside];
    RACSignal *reset = [self.resetButton rac_signalForControlEvents:UIControlEventTouchUpInside];
    RACSignal *cancel = [self.cancelButton rac_signalForControlEvents:UIControlEventTouchUpInside];
    RACSignal *doneOrReset = [RACSignal merge:@[done, reset]];
    
    self.fetchFirstStoryCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id _) {
        return [[[StoryManager sharedManager] fetchStorySignal] takeUntil:cancel];
    }];


    
    [self.fetchFirstStoryCommand.executionSignals.switchToLatest subscribeNext:^(NSDictionary *result) {
        [self startNextChapterWithContents:result cancelSignal:doneOrReset];
        [self.timerCommand execute:nil];
    }];
    
    self.fetchNextStoryCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        return [[[StoryManager sharedManager] fetchNextStorySignal] takeUntil:doneOrReset];
    }];
    
    [self.fetchNextStoryCommand.executionSignals.switchToLatest subscribeNext:^(NSDictionary *result) {
        [self startNextChapterWithContents:result cancelSignal:doneOrReset];
    }];
    
    [[RACSignal merge:@[self.fetchFirstStoryCommand.errors,self.fetchNextStoryCommand.errors]]
        subscribeNext:^(NSError *error) {
            [self showAlertWithTitle:@"Loading Story Error" message:error.localizedDescription];
    }];
    
    self.timerCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        return [[self timerSignal] takeUntil:doneOrReset];
    }];
    
    self.startButton.rac_command = self.fetchFirstStoryCommand;

    
    self.resetButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        @weakify(self)
        return [[RACObserve(self.timerCommand, executing)
                 take:1]
                doCompleted:^{
                    @strongify(self)
                    [self resetRun];
                }];
    }];
    
    [done subscribeNext:^(id x) {
        [self finishedRun];
    }];
}

- (void)startNextChapterWithContents:(NSDictionary *)result cancelSignal:cancelSignal
{
    [[StoryManager sharedManager] tellStoryWithContents:result];
    [[LocationManager sharedManager] searchForLocationsInContent:result];
    
    RACSignal *nextStorySignal = [[RACSignal zip:@[[[StoryManager sharedManager] storySignal],
                                                   [[LocationManager sharedManager] foundLocationSignal]]
                                          reduce:^id(id _, NSNumber *last){
                                              return last;
                                          }]
                                            take:1];
    
    [nextStorySignal subscribeNext:^(NSNumber *last) {
        BOOL isDestination = last.boolValue;
        if (isDestination) {
            [self reachedDestination];
        } else {
            [self.fetchNextStoryCommand execute:nil];
        }
    }];
}

- (void)reachedDestination
{
    
}

- (void)bindUI {
    RACSignal *startButtonHidden = [RACSignal combineLatest:@[self.fetchNextStoryCommand.executing,
                                                              self.timerCommand.executing]
                                                     reduce:^id(NSNumber *next, NSNumber *start, NSNumber *timer){
                                                         BOOL fetchingStory = start.boolValue;
                                                         BOOL fetchingNext = next.boolValue;
                                                         BOOL timing = timer.boolValue;
                                                
                                                         return @(fetchingStory || timing || fetchingNext);
                                                     }];
    
    RAC(self.startButton, hidden) = startButtonHidden;
    
    RAC(self.timerLabel, text) = self.timerCommand.executionSignals.switchToLatest;
    RAC(self.timerLabel, hidden) = self.timerCommand.executing.not;
    RAC(self.doneButton, hidden) = self.timerCommand.executing.not;
    RAC(self.resetButton, hidden) = self.timerCommand.executing.not;
    
    RAC(self.cancelButton, hidden) = self.fetchFirstStoryCommand.executing.not;
    RAC(self.activityIndicator, hidden) = self.fetchFirstStoryCommand.executing.not;
    RAC([UIApplication sharedApplication], networkActivityIndicatorVisible) = self.fetchFirstStoryCommand.executing;
}

- (void)finishedRun {
    
}

- (void)resetRun {
    [self.fetchFirstStoryCommand execute:nil];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (RACSignal *)timerSignal {
    NSDate *startDate = [NSDate date];
    
    RACSignal *intervalSignal = [RACSignal interval:1.0 onScheduler:[RACScheduler scheduler]];
    RACSignal *startedIntervalSignal = [intervalSignal startWith:[NSDate date]];
    RACSignal *mappedIntervalSignal = [[startedIntervalSignal map:^id(NSDate *value) {
        
        NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitMinute|NSCalendarUnitHour|NSCalendarUnitSecond fromDate:startDate toDate:value options:NSCalendarWrapComponents];
        
        return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)dateComponents.hour, (long)dateComponents.minute, (long) dateComponents.second];
    }] deliverOnMainThread];
    
    return mappedIntervalSignal;
}



@end
