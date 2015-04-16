//
//  StoryManager.m
//  ReactiveStorytime
//
//  Created by Alex Xiao on 3/16/15.
//  Copyright (c) 2015 Stever2Startup. All rights reserved.
//


#import "StoryManager.h"
#import <AFNetworking-RACExtensions/RACAFNetworking.h>
#import <AVFoundation/AVFoundation.h>

#define SENTENCE_DELAY 5.0

@interface StoryManager()

@property (nonatomic, strong) NSMutableArray *storySentences;
@property (nonatomic, strong) NSDictionary *json;
@property (nonatomic, strong) RACSignal *nextStory;

@end


@implementation StoryManager


+ (instancetype)sharedManager
{
    static StoryManager *manager;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        manager = [StoryManager new];
    });
    return manager;
}

- (void)tellStory:(NSString *)story withJson:(NSDictionary *)json cancelSignal:(RACSignal *)cancelSignal {
    
}


- (RACSignal *)tellStorySignal:(NSString *)story withJson:(NSDictionary *)json cancelSignal:(RACSignal *)cancelSignal {
    self.storySentences = [[story componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@".?!"]] mutableCopy];
    self.json = json;
    
    
    
    RACSignal *speech = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
    }];
    
    return
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    
}

- (RACSignal *)fetchStorySignal {
    NSString *url = @"http://localhost:8080/story";
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] init];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    NSDictionary *params = @{@"lat":@"37.4292", @"lng":@"-122.13181"};
    return [manager rac_GET:url parameters:params];
}

- (RACSignal *)fetchNextStorySignal {
    NSString *url = @"http://localhost:8080/story";
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] init];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    NSDictionary *params = @{@"lat":@"37.4292", @"lng":@"-122.13181"};
    return [manager rac_GET:url parameters:params];

    
}


@end
