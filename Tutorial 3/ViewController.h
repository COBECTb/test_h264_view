#import <UIKit/UIKit.h>
#import "GStreamerBackendDelegate.h"
#import "JSAnalogueStick.h"
#import "JSDPad.h"

@interface ViewController : UIViewController <GStreamerBackendDelegate,JSAnalogueStickDelegate,NSStreamDelegate> {
    IBOutlet UILabel *message_label;
    IBOutlet UIBarButtonItem *play_button;
    IBOutlet UIBarButtonItem *pause_button;
    IBOutlet UIView *video_view;
    IBOutlet UIView *video_container_view;
    IBOutlet NSLayoutConstraint *video_width_constraint;
    IBOutlet NSLayoutConstraint *video_height_constraint;
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    int cam_x;
    int cam_y;
    NSTimer *_timer;
}
@property (weak, nonatomic) IBOutlet JSAnalogueStick *LeftAS;
@property (weak, nonatomic) IBOutlet JSDPad *RightPad;

-(IBAction) play:(id)sender;
-(IBAction) pause:(id)sender;

/* From GStreamerBackendDelegate */
-(void) gstreamerInitialized;
-(void) gstreamerSetUIMessage:(NSString *)message;

@end
