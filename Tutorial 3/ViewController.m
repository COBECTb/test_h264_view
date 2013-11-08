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

int PWM = 0;
int GPIO = 1;

@implementation ViewController

/*
 * Methods from UIViewController
 */

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    play_button.enabled = FALSE;
    pause_button.enabled = FALSE;
    cam_x = 35930;
    cam_y = 38540;
    
    /* Make these constant for now, later tutorials will change them */
    media_width = 320;
    media_height = 240;
    gst_backend = [[GStreamerBackend alloc] init:self videoView:video_view];
    printf("viewDidLoad");
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
//    CFStringRef remoteHost = CFSTR("178.236.245.50");
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
    
    NSData *data= [ViewController makeCommandFor:PWM Number:1 andValue:cam_x];
	[outputStream write:[data bytes] maxLength:[data length]];
    data= [ViewController makeCommandFor:PWM Number:0 andValue:cam_y];;
	[outputStream write:[data bytes] maxLength:[data length]];
    [gst_backend play];
}

/* Called when the Pause button is pressed */
-(IBAction) pause:(id)sender
{
    [gst_backend pause];
    [inputStream close];
    [outputStream close];
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
    NSLog([NSString stringWithFormat:@"Left: %.1f", self->_LeftAS.xValue]);
    NSLog([NSString stringWithFormat:@"Left: %.1f", self->_LeftAS.yValue]);
    if(_timer.isValid)
    {
        if(self->_LeftAS.xValue==0&&self->_LeftAS.yValue==0)
           [_timer invalidate];
    }
    else
    {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(timerFireMethod) userInfo:NULL repeats:true];
    }
}

- (void)dPad:(JSDPad *)dPad didPressDirection:(JSDPadDirection)direction
{
	NSLog(@"Changing direction to: %d", direction);
    
    if(direction==JSDPadDirectionUp)
    {
        NSData *data;
        data= [ViewController makeCommandFor:GPIO Number:30 andValue:1];
        [outputStream write:[data bytes] maxLength:[data length]];
        data= [ViewController makeCommandFor:GPIO Number:31 andValue:1];
        [outputStream write:[data bytes] maxLength:[data length]];
        data= [ViewController makeCommandFor:GPIO Number:32 andValue:1];
        [outputStream write:[data bytes] maxLength:[data length]];
        data= [ViewController makeCommandFor:GPIO Number:33 andValue:1];
        [outputStream write:[data bytes] maxLength:[data length]];
    }
    else if(direction==JSDPadDirectionLeft)
    {
        NSData *data;
        data= [ViewController makeCommandFor:GPIO Number:30 andValue:1];
        [outputStream write:[data bytes] maxLength:[data length]];
        data= [ViewController makeCommandFor:GPIO Number:31 andValue:1];
        [outputStream write:[data bytes] maxLength:[data length]];
        data= [ViewController makeCommandFor:GPIO Number:32 andValue:0];
        [outputStream write:[data bytes] maxLength:[data length]];
        data= [ViewController makeCommandFor:GPIO Number:33 andValue:0];
        [outputStream write:[data bytes] maxLength:[data length]];
    }
    else if(direction==JSDPadDirectionRight)
    {
        NSData *data;
        data= [ViewController makeCommandFor:GPIO Number:30 andValue:0];
        [outputStream write:[data bytes] maxLength:[data length]];
        data= [ViewController makeCommandFor:GPIO Number:31 andValue:0];
        [outputStream write:[data bytes] maxLength:[data length]];
        data= [ViewController makeCommandFor:GPIO Number:32 andValue:1];
        [outputStream write:[data bytes] maxLength:[data length]];
        data= [ViewController makeCommandFor:GPIO Number:33 andValue:1];
        [outputStream write:[data bytes] maxLength:[data length]];
    }
}

- (void)dPadDidReleaseDirection:(JSDPad *)dPad
{
    NSData *data;
    data= [ViewController makeCommandFor:GPIO Number:30 andValue:0];
    [outputStream write:[data bytes] maxLength:[data length]];
    data= [ViewController makeCommandFor:GPIO Number:31 andValue:0];
    [outputStream write:[data bytes] maxLength:[data length]];
    data= [ViewController makeCommandFor:GPIO Number:32 andValue:0];
    [outputStream write:[data bytes] maxLength:[data length]];
    data= [ViewController makeCommandFor:GPIO Number:33 andValue:0];
    [outputStream write:[data bytes] maxLength:[data length]];
}

+(NSData*)makeCommandFor:(int)port Number:(int)number andValue:(int)value
{
    if(port==0)
        NSLog([NSString stringWithFormat:@"set pwm%d duty:%d period:%d\n",number, value]);
    else
        NSLog([NSString stringWithFormat:@"set con%d output:%d\n",number, value]);
    NSMutableData *typedata = [NSMutableData dataWithBytes: &port length: 1];
    NSMutableData *numberdata = [NSMutableData dataWithBytes: &number length: 1];
    NSData *valuedata = [NSData dataWithBytes: &value length: 2];
    [numberdata appendData:valuedata];
    [typedata appendData:numberdata];
    return typedata;
}

- (void)timerFireMethod
{
    int ncam_x=cam_x + 500*(self->_LeftAS.xValue)*-1;
    if(ncam_x<=65000&&ncam_x>=16000) cam_x=ncam_x;
    NSData *data= [ViewController makeCommandFor:PWM Number:1 andValue:cam_x];;
    [outputStream write:[data bytes] maxLength:[data length]];
    int ncam_y=cam_y + 500*(self->_LeftAS.yValue);
    if(ncam_y<=56000&&ncam_y>=19000) cam_y=ncam_y;
    data= [ViewController makeCommandFor:PWM Number:0 andValue:cam_y];;
    [outputStream write:[data bytes] maxLength:[data length]];
}

@end
