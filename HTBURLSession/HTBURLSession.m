//
//  HTBURLSession.m
//  HTBURLSession Demo App
//
//  Created by Mark Aufflick on 4/12/2013.
//  Copyright (c) 2013 The High Technology Bureau. All rights reserved.
//

#import "HTBURLSession.h"

@interface HTBURLSession ()

@property (nonatomic, strong) NSURLSession * theURLSession;

@end

@implementation HTBURLSession

+ (HTBURLSession *)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration
{
    HTBURLSession * s = [[self alloc] init];
    s.theURLSession = [NSURLSession sessionWithConfiguration:configuration];
    return s;
}

+ (HTBURLSession *)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration delegate:(id <NSURLSessionDelegate>)delegate delegateQueue:(NSOperationQueue *)queue
{
    HTBURLSession * s = [[self alloc] init];
    s.theURLSession = [NSURLSession sessionWithConfiguration:configuration delegate:delegate delegateQueue:queue];
    return s;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [self.theURLSession respondsToSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [NSURLSession instanceMethodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    if ([self.theURLSession respondsToSelector:[anInvocation selector]])
        [anInvocation invokeWithTarget:self.theURLSession];
    else
        [super forwardInvocation:anInvocation];
}

@end
