//
//  ViewController.m
//  FBVideoUpload
//
//  Created by Muhammad Zeeshan on 3/29/14.
//  Copyright (c) 2014 Muhammad Zeeshan. All rights reserved.
//

#import "ViewController.h"

#import <FacebookSDK/FacebookSDK.h>
#import "AFNetworking.h"
#import "SVProgressHUD.h"

static void *ProgressObserverContext = &ProgressObserverContext;

@interface ViewController ()
{
    IBOutlet UITextField *titleTextField;
    IBOutlet UITextView *descriptionTextView;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - Facebook Methods -
-(void)initiateFacebookSessionIfNot
{
    if (FBSession.activeSession.isOpen)
    {
        [self uploadVideo];
    }
    else
    {
        NSArray *permissionsArray = @[@"publish_stream"];
        [FBSession openActiveSessionWithPublishPermissions:permissionsArray defaultAudience:FBSessionDefaultAudienceOnlyMe allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            if (error)
            {
                NSString *alertMessage, *alertTitle;
                
                if (error.fberrorShouldNotifyUser) {
                    alertTitle = @"Something Went Wrong";
                    alertMessage = error.fberrorUserMessage;
                } else if (error.fberrorCategory == FBErrorCategoryUserCancelled) {
                    NSLog(@"user cancelled login");
                } else {
                    // For simplicity, this sample treats other errors blindly.
                    alertTitle  = @"Unknown Error";
                    alertMessage = @"Error. Please try again later.";
                    NSLog(@"Unexpected error:%@", error);
                }
                
                if (alertMessage)
                {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                    [alertView show];
                }
            }
            else if (FB_ISSESSIONOPENWITHSTATE(status))
            {
                [self uploadVideo];
            }
        }];
    }
}
#pragma mark - My Methods -
- (void)uploadVideo
{
    [SVProgressHUD showWithStatus:@"Loading..." maskType:SVProgressHUDMaskTypeGradient];
    
    NSURL *videoURL = [[NSBundle mainBundle] URLForResource:@"Tune.pk - Wired usb keyboard to wireless keyboard converter." withExtension:@"mp4"];
    NSString *fileName = [[videoURL lastPathComponent] stringByRemovingPercentEncoding];
    
    NSString *graphPath = [NSString stringWithFormat:@"https://graph.facebook.com/me/videos?access_token=%@",[[[FBSession activeSession] accessTokenData] accessToken]];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:titleTextField.text forKey:@"title"];
    [params setObject:descriptionTextView.text forKey:@"description"];
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:graphPath parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        NSString *fileMimeType = @"video/mp4";
        NSError *error;
        [formData appendPartWithFileURL:videoURL name:@"video" fileName:fileName mimeType:fileMimeType error:&error];
        if(error)
            NSLog(@"Error: %@",error);
    } error:nil];
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSProgress *progress = nil;
    NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithStreamedRequest:request progress:&progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        
        [SVProgressHUD dismiss];
        
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            [SVProgressHUD showSuccessWithStatus:@"Uploaded"];
            NSLog(@"%@ %@", response, responseObject);
        }
    }];
    
    [uploadTask resume];
    
    [progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionInitial context:ProgressObserverContext];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(context == ProgressObserverContext)
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSProgress *progress = object;
            [SVProgressHUD showProgress:progress.fractionCompleted status:@"Uploading..." maskType:SVProgressHUDMaskTypeGradient];
        }];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
#pragma mark - My IBActions -
- (IBAction)uploadButtonTapped:(UIButton *)sender
{
    [self initiateFacebookSessionIfNot];
}
- (IBAction)textFieldDidEndOnExit:(id)sender
{
    
}
@end
