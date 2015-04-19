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
#import "Globals.h"

#define SENTENCE_DELAY 5.0

@interface StoryManager() <AVSpeechSynthesizerDelegate>

@property (nonatomic, strong) NSMutableArray *storySentences;
@property (nonatomic, strong) RACSubject *finishedStorySubject;
@property (nonatomic, strong) AVSpeechSynthesizer *speechSynthesizer;

@end


@implementation StoryManager


- (instancetype)init
{
    if (self = [super init]) {
        _finishedStorySubject = [RACSubject subject];
        _speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
        _speechSynthesizer.delegate = self;
    }
    return self;
}

+ (instancetype)sharedManager
{
    static StoryManager *manager;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        manager = [StoryManager new];
    });
    return manager;
}



- (RACSignal *)storySignalWithStory:(NSString *)story {
    self.storySentences = [[story componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@".?!"]] mutableCopy];

    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        if (self.storySentences.count) {
            [self.finishedStorySubject subscribe:subscriber];
            [self speakNextUtterance];
            
        } else {
            [subscriber sendError:[NSError errorWithDomain:kStoryErrorDomain
                                                      code:StoryErrorEmpty
                                                  userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Recieved an empty story", nil)}]];
        }
        
        return [RACDisposable disposableWithBlock:^{
            [self.storySentences removeAllObjects];
            [self stopSpeech];
        }];
    }];
}

- (void)stopSpeech
{
    if([_speechSynthesizer isSpeaking]) {
        [_speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:@""];
        [_speechSynthesizer speakUtterance:utterance];
        [_speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }
}


- (void)speakNextUtterance {
    if (self.storySentences.count) {
        NSString *nextText = self.storySentences[0];
        [self.storySentences removeObjectAtIndex:0];
        
        AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:nextText];
        utterance.pitchMultiplier = 0.8;
        utterance.rate = 10.0;
        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-GB"];
        
        [self.speechSynthesizer speakUtterance:utterance];
    }
   
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    if (self.storySentences.count) {
        [self performSelector:@selector(speakNextUtterance)
                   withObject:nil
                   afterDelay:1.0];
    } else {
        NSLog(@"finsihed story!");
        [self.finishedStorySubject sendNext:nil];
    }
}




@end
