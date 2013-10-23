#import "ViewController.h"
#import "GStreamerBackend.h"
#import <UIKit/UIKit.h>
//#import <CoreServices/CFSocketStream.h>
//#import <CoreServices/CFStream.h>

@interface ViewController () {
    GStreamerBackend *gst_backend;
    int media_width;
    int media_height;
}

@end

@implementation ViewController

/*
 * Methods from UIViewController
 */

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    play_button.enabled = FALSE;
    pause_button.enabled = FALSE;
    
    cam_x = 25000;
    cam_y = 25000;
    
    /* Make these constant for now, later tutorials will change them */
    media_width = 320;
    media_height = 240;
    _LeftAS.number = 1;
    _RightAS.number = 2;
    gst_backend = [[GStreamerBackend alloc] init:self videoView:video_view];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/* Called when the Play button is pressed */
-(IBAction) play:(id)sender
{
    [gst_backend play];
    // Create socket pair:
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStringRef remoteHost = CFSTR("192.168.2.1");
    CFStreamCreatePairWithSocketToHost(NULL, remoteHost, 4444, &readStream, &writeStream);
    inputStream = (__bridge_transfer NSInputStream *)readStream;
    outputStream = (__bridge_transfer NSOutputStream *)writeStream;
    [inputStream setDelegate:self];
    
    [outputStream setDelegate:self];
    
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [inputStream open];
    
    [outputStream open];
    
    NSString *response  = [NSString stringWithFormat:@"set pwm1 duty:%d period:476190\n", cam_x];
    NSLog(response);
	NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
	[outputStream write:[data bytes] maxLength:[data length]];
    response  = [NSString stringWithFormat:@"set pwm0 duty:%d period:476190\n", cam_y];
	data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
	[outputStream write:[data bytes] maxLength:[data length]];
}

/* Called when the Pause button is pressed */
-(IBAction) pause:(id)sender
{
    [gst_backend pause];
}

- (void)viewDidLayoutSubviews
{
    CGFloat view_width = video_container_view.bounds.size.width;
    CGFloat view_height = video_container_view.bounds.size.height;

    CGFloat correct_height = view_width * media_height / media_width;
    CGFloat correct_width = view_height * media_width / media_height;

    if (correct_height < view_height) {
        video_height_constraint.constant = correct_height;
        video_width_constraint.constant = view_width;
    } else {
        video_width_constraint.constant = correct_width;
        video_height_constraint.constant = view_height;
    }
}

/*
 * Methods from GstreamerBackendDelegate
 */

-(void) gstreamerInitialized
{
    dispatch_async(dispatch_get_main_queue(), ^{
        play_button.enabled = TRUE;
        pause_button.enabled = TRUE;
        message_label.text = @"Ready";
    });
}

-(void) gstreamerSetUIMessage:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        message_label.text = message;
    });
}

#pragma mark - JSAnalogueStickDelegate

- (void)analogueStickDidChangeValue:(JSAnalogueStick *)analogueStick
{
    if(analogueStick.number == 1)
    {
        NSLog([NSString stringWithFormat:@"Left: %.1f", self->_LeftAS.xValue]);
        NSLog([NSString stringWithFormat:@"Left: %.1f", self->_LeftAS.yValue]);
        int ncam_x=cam_x + 500*(self->_LeftAS.xValue)*-1;
        if(ncam_x<=140000&&ncam_x>=12000) cam_x=ncam_x;
        NSString *response  = [NSString stringWithFormat:@"set pwm1 duty:%d period:476190\n", cam_x];
        NSLog(response);

        int ncam_y=cam_y + 500*(self->_LeftAS.yValue);
        if(ncam_y<=52000&&ncam_y>=19000) cam_y=ncam_y;
        NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
        [outputStream write:[data bytes] maxLength:[data length]];
        response  = [NSString stringWithFormat:@"set pwm0 duty:%d period:476190\n", cam_y];
        data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
        [outputStream write:[data bytes] maxLength:[data length]];
    }
    else
    {
        NSLog([NSString stringWithFormat:@"Right: %.1f , %.1f", self->_RightAS.xValue, self->_RightAS.yValue]);
    }
}

@end
