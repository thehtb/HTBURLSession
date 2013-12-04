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
static NSString * HTBURLSessionDataTaskCompletionHandlerKey = @"HTBURLSessionDataTaskCompletionHandlerKey";
static NSString * HTBURLSessionDataTaskReceivedDataKey = @"HTBURLSessionDataTaskReceivedDataKey";


static void CallAssociatedDownloadTaskCompletionHandler(NSURLSessionTask * task, NSURL * url, NSError * error);
static void CallAssociatedDataTaskCompletionHandler(NSURLSessionTask * task, NSError * error);
static void AccumulateDataTaskReceivedData(NSURLSessionTask * task, NSData * data);

@interface HTBURLSession () <NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession * theURLSession;
@property (nonatomic, strong) NSObject<NSURLSessionDelegate> * theUserDelegate;

@end

@implementation HTBURLSession

+ (HTBURLSession *)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration
{
    HTBURLSession * s = [[self alloc] init];
    s.theURLSession = [NSURLSession sessionWithConfiguration:configuration delegate:s delegateQueue:nil];
    return s;
}

+ (HTBURLSession *)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration delegate:(id <NSURLSessionDelegate>)delegate delegateQueue:(NSOperationQueue *)queue
{
    HTBURLSession * s = [[self alloc] init];
    s.theUserDelegate = delegate;
    s.theURLSession = [NSURLSession sessionWithConfiguration:configuration delegate:s delegateQueue:queue];
    return s;
}

- (id<NSURLSessionDelegate>)delegate
{
    // fortunately, NSURLSession doesn't ask for the delegate by method, otherwise we couldn't hide this implementation detail
    //TODO: some tests to check for if this changes...
    return self.theUserDelegate;
}

#pragma mark - Overridden completionHandler convenience methods

#define ReturnAssociatedCompletionHandler(key) objc_setAssociatedObject(task, (__bridge void *)key, completionHandler, OBJC_ASSOCIATION_RETAIN_NONATOMIC); return task

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler
{
    NSURLSessionDataTask * task = [self.theURLSession dataTaskWithRequest:request];
    ReturnAssociatedCompletionHandler(HTBURLSessionDataTaskCompletionHandlerKey);
}

- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url
                        completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler
{
    NSURLSessionDataTask * task = [self.theURLSession dataTaskWithURL:url];
    ReturnAssociatedCompletionHandler(HTBURLSessionDataTaskCompletionHandlerKey);
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL
                                completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler
{
    NSURLSessionUploadTask * task = [self.theURLSession uploadTaskWithRequest:request fromFile:fileURL];
    
    // an upload task is basically a data task that also happens to have a chunky body
    ReturnAssociatedCompletionHandler(HTBURLSessionDataTaskCompletionHandlerKey);
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData
                                completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler
{
    NSURLSessionUploadTask * task = [self.theURLSession uploadTaskWithRequest:request fromData:bodyData];
    
    // an upload task is basically a data task that also happens to have a chunky body
    ReturnAssociatedCompletionHandler(HTBURLSessionDataTaskCompletionHandlerKey);
}

- (NSURLSessionDownloadTask *)downloadTaskWithURL:(NSURL *)url
                                completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error))completionHandler
{
    NSURLSessionDownloadTask * task = [self.theURLSession downloadTaskWithURL:url];
    ReturnAssociatedCompletionHandler(HTBURLSessionDownloadTaskCompletionHandlerKey);
}

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
                                    completionHandler:(void (^)(NSURL *, NSURLResponse *, NSError *))completionHandler
{
    NSURLSessionDownloadTask * task = [self.theURLSession downloadTaskWithRequest:request];
    ReturnAssociatedCompletionHandler(HTBURLSessionDownloadTaskCompletionHandlerKey);
}

- (NSURLSessionDownloadTask *)downloadTaskWithResumeData:(NSData *)resumeData
                                       completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error))completionHandler
{
    NSURLSessionDownloadTask * task = [self.theURLSession downloadTaskWithResumeData:resumeData];
    ReturnAssociatedCompletionHandler(HTBURLSessionDownloadTaskCompletionHandlerKey);
}

#pragma mark - message forwarding for both url session and delegate

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

#pragma mark - required delegate methods to keep llvm happy

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
                                           didWriteData:(int64_t)bytesWritten
                                      totalBytesWritten:(int64_t)totalBytesWritten
                              totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    if ([self.theUserDelegate respondsToSelector:@selector(URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)])
        [(id<NSURLSessionDownloadDelegate>)self.theUserDelegate URLSession:session downloadTask:downloadTask didWriteData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
                                      didResumeAtOffset:(int64_t)fileOffset
                                     expectedTotalBytes:(int64_t)expectedTotalBytes
{
    if ([self.theUserDelegate respondsToSelector:@selector(URLSession:downloadTask:didResumeAtOffset:expectedTotalBytes:)])
        [(id<NSURLSessionDownloadDelegate>)self.theUserDelegate URLSession:session downloadTask:downloadTask didResumeAtOffset:fileOffset expectedTotalBytes:expectedTotalBytes];
}

#pragma mark - Implemented delegate methods

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
                        didCompleteWithError:(NSError *)error
{
    if ([self.theUserDelegate respondsToSelector:@selector(URLSession:task:didCompleteWithError:)])
        [(id<NSURLSessionTaskDelegate>)self.theUserDelegate URLSession:session task:task didCompleteWithError:error];

    CallAssociatedDataTaskCompletionHandler(task, error);

    if (error != nil)
        CallAssociatedDownloadTaskCompletionHandler(task, nil, error);

}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    if ([self.theUserDelegate respondsToSelector:@selector(URLSession:dataTask:didReceiveData:)])
        [(id<NSURLSessionDataDelegate>)self.theUserDelegate URLSession:session dataTask:dataTask didReceiveData:data];
    
    AccumulateDataTaskReceivedData(dataTask, data);
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
                              didFinishDownloadingToURL:(NSURL *)location
{
    if ([self.theUserDelegate respondsToSelector:@selector(URLSession:downloadTask:didFinishDownloadingToURL:)])
        [(id<NSURLSessionDownloadDelegate>)self.theUserDelegate URLSession:session downloadTask:downloadTask didFinishDownloadingToURL:location];
    
    CallAssociatedDownloadTaskCompletionHandler(downloadTask, location, nil);
}

@end

#define AssociatedObjectForKey(key) objc_getAssociatedObject(task, (__bridge void *)key)
#define RemoveAssociatedKey(key) objc_setAssociatedObject(task, (__bridge void *)key, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC)

static void AccumulateDataTaskReceivedData(NSURLSessionTask * task, NSData * data)
{
    NSMutableData * accumulatedData = AssociatedObjectForKey(HTBURLSessionDataTaskReceivedDataKey);
    if (accumulatedData == nil)
    {
        accumulatedData = [data mutableCopy];
        objc_setAssociatedObject(task, (__bridge void *)HTBURLSessionDataTaskReceivedDataKey, accumulatedData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    else
    {
        [accumulatedData appendData:data];
    }
}

static void CallAssociatedDownloadTaskCompletionHandler(NSURLSessionTask * task, NSURL * url, NSError * error)
{
    void (^completionHandler)(NSURL *, NSURLResponse *, NSError *) = AssociatedObjectForKey(HTBURLSessionDownloadTaskCompletionHandlerKey);
    
    if (completionHandler != nil)
    {
        completionHandler(url, task.response, error);
        RemoveAssociatedKey(HTBURLSessionDownloadTaskCompletionHandlerKey);
    }
}

static void CallAssociatedDataTaskCompletionHandler(NSURLSessionTask * task, NSError * error)
{
    void (^completionHandler)(NSData *data, NSURLResponse *response, NSError *error) = AssociatedObjectForKey(HTBURLSessionDataTaskCompletionHandlerKey);
    
    if (completionHandler != nil)
    {
        NSData * data = AssociatedObjectForKey(HTBURLSessionDataTaskReceivedDataKey);
        completionHandler(data, task.response, error);
        RemoveAssociatedKey(HTBURLSessionDataTaskCompletionHandlerKey);
    }
    
    RemoveAssociatedKey(HTBURLSessionDataTaskReceivedDataKey);
}
