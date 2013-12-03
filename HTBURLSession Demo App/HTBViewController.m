//
//  HTBViewController.m
//  HTBURLSession Demo App
//
//  Created by Mark Aufflick on 4/12/2013.
//  Copyright (c) 2013 The High Technology Bureau. All rights reserved.
//

#import "HTBViewController.h"
#import "HTBURLSession.h"

@interface HTBViewController () <NSURLSessionTaskDelegate>

@property (nonatomic, readonly) HTBURLSession * urlSession;

@end

@implementation HTBViewController

@synthesize urlSession=_urlSession;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (HTBURLSession *)urlSession
{
    if (_urlSession == nil)
    {
        NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _urlSession = [HTBURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }
    
    return _urlSession;
}

- (IBAction)get:(id)sender
{
    NSURL * rssURL = [NSURL URLWithString:@"http://api.flickr.com/services/feeds/photos_public.gne"];
    NSURLRequest * rssReq = [NSURLRequest requestWithURL:rssURL];
    NSURLSessionDataTask * task = [self.urlSession dataTaskWithRequest:rssReq];
    [task resume];
}

#pragma mark - NSURLSessionTaskDelegate methods

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    NSLog(@"completed: %@", [error localizedDescription] ?: @"OK");
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    NSLog(@"progress: %lld/%lld", totalBytesSent, totalBytesExpectedToSend);
}


@end
