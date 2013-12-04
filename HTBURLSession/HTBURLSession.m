//
//  HTBURLSession.m
//  HTBURLSession Demo App
//
//  Created by Mark Aufflick on 4/12/2013.
//  Copyright (c) 2013 The High Technology Bureau. All rights reserved.
//

#import "HTBURLSession.h"
#import <objc/runtime.h>

static NSString * HTBURLSessionDownloadTaskCompletionHandlerKey = @"HTBURLSessionDownloadTaskCompletionHandlerKey";

@interface HTBURLSession () <NSURLSessionDelegate, NSURLSessionDownloadDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession * theURLSession;
@property (nonatomic, strong) NSObject<NSURLSessionDelegate> * theUserDelegate;

@end

@implementation HTBURLSession

+ (HTBURLSession *)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration
{
    HTBURLSession * s = [[self alloc] init];
    // when we add support for progress block callback's we'll want to set ourselves as delegate here also
    s.theURLSession = [NSURLSession sessionWithConfiguration:configuration];
    return s;
}

+ (HTBURLSession *)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration delegate:(id <NSURLSessionDelegate>)delegate delegateQueue:(NSOperationQueue *)queue
{
    HTBURLSession * s = [[self alloc] init];
    s.theUserDelegate = delegate;
    s.theURLSession = [NSURLSession sessionWithConfiguration:configuration delegate:s delegateQueue:queue];
    return s;
}

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURL *, NSURLResponse *, NSError *))completionHandler
{
    NSURLSessionDownloadTask * downloadTask = [self.theURLSession downloadTaskWithRequest:request completionHandler:nil];
    objc_setAssociatedObject(downloadTask, (__bridge void *)HTBURLSessionDownloadTaskCompletionHandlerKey, completionHandler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return downloadTask;
}

//TODO: the rest of the block methods

- (id<NSURLSessionDelegate>)delegate
{
    // fortunately, NSURLSession doesn't ask for the delegate by method, otherwise we couldn't hide this implementation detail
    //TODO: some tests to check for if this changes...
    return self.theUserDelegate;
}

#pragma mark - message forwarding

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [self.theURLSession respondsToSelector:aSelector] ?: [super respondsToSelector:aSelector] ?: [self.theUserDelegate respondsToSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [NSURLSession instanceMethodSignatureForSelector:aSelector] ?: [super methodSignatureForSelector:aSelector] ?: [self.theUserDelegate methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    if ([self.theURLSession respondsToSelector:[anInvocation selector]])
        [anInvocation invokeWithTarget:self.theURLSession];
    else if ([self.theUserDelegate respondsToSelector:[anInvocation selector]])
        [anInvocation invokeWithTarget:self.theUserDelegate];
    else
        [super forwardInvocation:anInvocation];
}

#pragma mark - delegate methods

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    if ([self.theUserDelegate respondsToSelector:@selector(URLSession:task:didCompleteWithError:)])
        [(id<NSURLSessionTaskDelegate>)self.theUserDelegate URLSession:session task:task didCompleteWithError:error];
    
    // if there was an error, need to find any block callback
    if (error != nil)
    {
        void (^completionHandler)(NSURL *, NSURLResponse *, NSError *) = objc_getAssociatedObject(task, (__bridge void *)HTBURLSessionDownloadTaskCompletionHandlerKey);
        if (completionHandler != nil)
            completionHandler(nil, nil, error); //TODO: I guess the response comes from another delegate callback?
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    if ([self.theUserDelegate respondsToSelector:@selector(URLSession:downloadTask:didFinishDownloadingToURL:)])
        [(id<NSURLSessionDownloadDelegate>)self.theUserDelegate URLSession:session downloadTask:downloadTask didFinishDownloadingToURL:location];
    
    void (^completionHandler)(NSURL *, NSURLResponse *, NSError *) = objc_getAssociatedObject(downloadTask, (__bridge void *)HTBURLSessionDownloadTaskCompletionHandlerKey);
    if (completionHandler != nil)
        completionHandler(location, nil, nil); //TODO: I guess the response comes from another delegate callback?
}

@end
