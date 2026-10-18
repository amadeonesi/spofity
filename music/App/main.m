#import <UIKit/UIKit.h>
#import "MMRootController.h"

// Sperrbildschirm-, Kopfhörer- und Auto-Tasten kommen als "Remote Control"-Ereignis beim First Responder an.
// Den gibt es nicht immer (z. B. solange der Player offen ist oder nach der Tastatur) -> dann gingen die Tasten ins Leere.
// Darum hier abfangen, wo jedes Ereignis durchläuft, und direkt an die Wiedergabe geben (genau einmal).
@interface MMApplication : UIApplication
@end
@implementation MMApplication
- (void)sendEvent:(UIEvent *)event {
    MMRootController*root=[MMRootController shared];
    if(event.type==UIEventTypeRemoteControl && root){ [root remoteControlReceivedWithEvent:event]; return; }
    [super sendEvent:event];
}
@end

int main(int argc, char *argv[]) {
    @autoreleasepool { return UIApplicationMain(argc, argv, @"MMApplication", @"MMAppDelegate"); }
}
