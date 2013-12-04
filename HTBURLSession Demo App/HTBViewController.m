//
//  HTBViewController.m
//  HTBURLSession Demo App
//
//  Created by Mark Aufflick on 4/12/2013.
//  Copyright (c) 2013 The High Technology Bureau. All rights reserved.
//

#import "HTBViewController.h"
#import "HTBURLSession.h"

@interface HTBViewController () <NSURLSessionDelegate>

@property (nonatomic, readonly) HTBURLSession * urlSession;
@property (weak, nonatomic) IBOutlet UIProgressView * progressView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView * activityView;
@property (weak, nonatomic) IBOutlet UIButton * getButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation HTBViewController

@synthesize urlSession=_urlSession;

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[_progressView]-(8@750)-[_getButton]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(_progressView, _getButton)]];
    
    [self hideActivityViewAnimated:NO];
    self.progressView.progress = 0;
}

- (void)dealloc
{
    self.activityView = nil;
}

- (void)showActivityView
{
    [UIView animateWithDuration:0.5
                     animations:^{
                         [self.view addSubview:self.activityView];
                         [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[_progressView]-(8@1000)-[_activityView(20@1000)]-(8@1000)-[_getButton]"
                                                                                           options:NSLayoutFormatAlignAllCenterY
                                                                                           metrics:nil
                                                                                             views:NSDictionaryOfVariableBindings(_progressView, _activityView, _getButton)]];

                         [self.view layoutIfNeeded];
                     }];
}

- (void)hideActivityViewAnimated:(BOOL)animated
{
    [self.activityView removeFromSuperview];

    if (animated)
        [UIView animateWithDuration:0.5
                         animations:^{
                             [self.view layoutIfNeeded];
                         }];
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
    self.progressView.progress = 0;

    [self showActivityView];
    [self.activityView startAnimating];
    
    NSURL * rssURL = [NSURL URLWithString:@"http://api.flickr.com/services/feeds/photos_public.gne?format=json&nojsoncallback=1"];
    NSURLRequest * rssReq = [NSURLRequest requestWithURL:rssURL];
    NSURLSessionDataTask * task = [self.urlSession dataTaskWithRequest:rssReq
                                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                             [self.activityView stopAnimating];
                                                             [self hideActivityViewAnimated:YES];
                                                         });
                                                         
                                                         if (error != nil)
                                                         {
                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                 UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Error downloading feed"
                                                                                                                  message:[error debugDescription]
                                                                                                                 delegate:nil
                                                                                                        cancelButtonTitle:@"OK"
                                                                                                        otherButtonTitles:nil];
                                                                 [alert show];
                                                             });
                                                         }
                                                         else
                                                         {
                                                             [self processFeedResponse:data];
                                                         }
                                                     }];
    [task resume];
}

- (void)processFeedResponse:(NSData *)data
{
    NSString * string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    string = [string stringByReplacingOccurrencesOfString:@"\\'" withString:@"'"]; // stupid flickr json
    
    NSError * jsonError;
    NSDictionary * json = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]
                                                          options:0
                                                            error:&jsonError];
    
    if (!json)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Error parsing feed"
                                                             message:[jsonError debugDescription]
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
            [alert show];
        });
    }
    else
    {
        NSString * imageURLString = ((NSDictionary *)[json[@"items"] firstObject])[@"media"][@"m"];
        NSAssert([imageURLString isKindOfClass:[NSString class]], @"Perhaps the flickr feed changed?");
        imageURLString = [imageURLString stringByReplacingOccurrencesOfString:@"_m.jpg" withString:@"_b.jpg"];
        [self downloadImageForURL:[NSURL URLWithString:imageURLString]];
    }
}

- (void)downloadImageForURL:(NSURL *)imageURL
{
    NSURLRequest * req = [NSURLRequest requestWithURL:imageURL];
    
    NSURLSessionDownloadTask * task = [self.urlSession downloadTaskWithRequest:req
                                                             completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                                 // NB: in a real app you usually want to move the file to a permanent location
                                                                 NSData * data = [NSData dataWithContentsOfURL:location];
                                                                 
                                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                                     self.imageView.image = [UIImage imageWithData:data];
                                                                 });
                                                             }];
    [task resume];
}

#pragma mark - NSURLSessionTaskDelegate methods

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    NSLog(@"completed in delegate: %@", [error localizedDescription] ?: @"OK");
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressView.progress = 1.;
    });
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressView.progress = totalBytesWritten / (float)totalBytesExpectedToWrite;
    });
}


@end
