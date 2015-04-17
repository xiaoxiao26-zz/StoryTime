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
#import "Globals.h"

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
        return [[self fetchStorySignal] takeUntil:cancel];
    }];
    [self.fetchFirstStoryCommand.executionSignals.switchToLatest subscribeNext:^(NSDictionary *result) {
        [self startNextChapterWithContents:result cancelSignal:doneOrReset];
        [self.timerCommand execute:nil];
    }];
    
    self.fetchNextStoryCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(RACSignal *fetchNextStorySignal) {
        return [fetchNextStorySignal takeUntil:doneOrReset];
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

- (RACSignal *)fetchStorySignal {
    NSString *url = @"http://localhost:8080/story";
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] init];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    NSDictionary *params = @{@"lat":@"37.4292", @"lng":@"-122.13181"};
    return [manager rac_GET:url parameters:params];
}


- (void)startNextChapterWithContents:(NSDictionary *)result cancelSignal:cancelSignal
{
    
    NSDictionary *targets = result[@"json"];
    NSString *story = result[@"text"];
    
    RACSignal *nextStorySignal = [[[RACSignal
                                    zip:@[[[StoryManager sharedManager] storySignalWithStory:story],
                                          [[LocationManager sharedManager] foundLocationSignalWithTargets:targets]]
                                    reduce:^id(id _, RACTuple *tuple){
                                        return tuple;
                                    }]
                                    take:1]
                                    takeUntil:cancelSignal];
    
    [nextStorySignal subscribeNext:^(RACTuple *tuple) {
        RACTupleUnpack(NSNumber *last, RACSignal *fetchNextStorySignal) = tuple;
        BOOL isDestination = last.boolValue;
        if (isDestination) {
            [self reachedDestination];
        } else {
            [self.fetchNextStoryCommand execute:fetchNextStorySignal];
        }
    }];
}

- (void)reachedDestination
{
    
}

- (void)bindUI {
    RACSignal *startButtonHidden = [RACSignal combineLatest:@[self.fetchFirstStoryCommand.executing,
                                                              self.timerCommand.executing]
                                                     reduce:^id(NSNumber *start, NSNumber *timer){
                                                         BOOL fetchingStory = start.boolValue;
                                                         BOOL timing = timer.boolValue;
                                                
                                                         return @(fetchingStory || timing);
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
