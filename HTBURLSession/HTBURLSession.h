//
//  HTBURLSession.h
//  HTBURLSession Demo App
//
//  Created by Mark Aufflick on 4/12/2013.
//  Copyright (c) 2013 The High Technology Bureau. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Drop-in equivalent replacement for NSURLSession with better blocks support.

The only NSURLSession method not supported is `sharedSession` which is a bad idea IMO anyway.

Behaviour should be identical to NSURLSession as all actual work is forwarded to an NSURLSession
instance internally. The only difference is that completion blocks and delegate callbacks are not
mutually exclusive (which they are with NSURLSession). */

@interface HTBURLSession : NSObject

/** Returns an instance of HTBURLSession.

Replaces NSURLSession's equivalent method, who's signature can't be used since it doesn't use instancetype.

*/
+ (instancetype)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration;

/** Returns an instance of HTBURLSession.

Replaces NSURLSession's equivalent method, who's signature can't be used since it doesn't use instancetype. Also note
that the delegate type is slightly different because the message forwarding relies on methods implemented by NSObject,
not just those in the NSObject protocol. (If you have no idea what that means, check Mike Ash's excellent blog post
on the topic: http://www.mikeash.com/pyblog/friday-qa-2013-10-25-nsobject-the-class-and-the-protocol.html )

*/
+ (instancetype)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration delegate:(NSObject <NSURLSessionDelegate> *)delegate delegateQueue:(NSOperationQueue *)queue;

@end

@interface HTBURLSession (NSURLSessionMethods)

@property (readonly, retain) id <NSURLSessionDelegate> delegate;
@property (readonly, retain) NSOperationQueue *delegateQueue;
@property (readonly, copy) NSURLSessionConfiguration *configuration;
@property (copy) NSString *sessionDescription;

- (void)finishTasksAndInvalidate;
- (void)invalidateAndCancel;
- (void)resetWithCompletionHandler:(void (^)(void))completionHandler;
- (void)flushWithCompletionHandler:(void (^)(void))completionHandler;
- (void)getTasksWithCompletionHandler:(void (^)(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks))completionHandler;
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request;
- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url;
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL;
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData;
- (NSURLSessionUploadTask *)uploadTaskWithStreamedRequest:(NSURLRequest *)request;
- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request;
- (NSURLSessionDownloadTask *)downloadTaskWithURL:(NSURL *)url;
- (NSURLSessionDownloadTask *)downloadTaskWithResumeData:(NSData *)resumeData;

// NSURLSessionAsynchronousConvenience

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;
- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;
- (NSURLSessionDownloadTask *)downloadTaskWithURL:(NSURL *)url completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error))completionHandler;
- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error))completionHandler;
- (NSURLSessionDownloadTask *)downloadTaskWithResumeData:(NSData *)resumeData completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error))completionHandler;

@end