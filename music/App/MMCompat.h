// iOS-5-Kompatibilität. Wird per -include (Makefile) vor jede Datei gesetzt; Deployment-Target ist 5.0, ein Binary für iOS 5 und 6.
// -Werror=unguarded-availability bleibt an: alles, was hier nicht steht, muss weiterhin echt geprüft werden.
#ifdef __OBJC__
// Für Empfänger vom Typ id sucht clang im globalen Methoden-Pool und nimmt die erste Deklaration. Dieses Protokoll steht deshalb
// vor Foundation, sonst greift bei x[@"a"][0] wieder die Deklaration mit "ab iOS 6".
@protocol MMCompatSubscript
- (id)objectForKeyedSubscript:(id)key;
- (void)setObject:(id)obj forKeyedSubscript:(id)key;
- (id)objectAtIndexedSubscript:(unsigned int)idx;   // = NSUInteger auf armv7
- (void)setObject:(id)obj atIndexedSubscript:(unsigned int)idx;
@end
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>   // iOS 5 UIKit forward-declares CALayer; layer.cornerRadius needs the real header

// iOS 5 SDK: these exist only in the iOS 6 headers. Values match the runtime constants.
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 60000
typedef NSUInteger UIInterfaceOrientationMask;
enum {
    UIInterfaceOrientationMaskPortrait           = (1 << UIInterfaceOrientationPortrait),
    UIInterfaceOrientationMaskLandscapeLeft      = (1 << UIInterfaceOrientationLandscapeLeft),
    UIInterfaceOrientationMaskLandscapeRight     = (1 << UIInterfaceOrientationLandscapeRight),
    UIInterfaceOrientationMaskPortraitUpsideDown = (1 << UIInterfaceOrientationPortraitUpsideDown),
    UIInterfaceOrientationMaskLandscape          = (UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight),
    UIInterfaceOrientationMaskAll                = (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft |
                                                    UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortraitUpsideDown),
    UIInterfaceOrientationMaskAllButUpsideDown   = (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft |
                                                    UIInterfaceOrientationMaskLandscapeRight)
};
@interface UILabel (MMCompat)
@property (nonatomic, copy) NSAttributedString *attributedText;   // iOS 6; guarded by respondsToSelector at runtime
@end
// iOS 6 interruption notifications. Same names/values as the iOS 6 SDK, used only when the notification fires.
#define AVAudioSessionInterruptionNotification      @"AVAudioSessionInterruptionNotification"
#define AVAudioSessionInterruptionTypeKey           @"AVAudioSessionInterruptionTypeKey"
#define AVAudioSessionInterruptionOptionKey         @"AVAudioSessionInterruptionOptionKey"
enum {
    AVAudioSessionInterruptionTypeEnded = 0,
    AVAudioSessionInterruptionTypeBegan = 1
};
enum {
    AVAudioSessionInterruptionOptionShouldResume = 1
};
#endif

// Objekt-Subscripting (d[@"k"], a[0], d[@"k"]=v, a[i]=v) gibt es erst ab iOS 6. libarclite, das die Methoden früher
// für iOS 5 nachrüstete, liefert Xcode nicht mehr mit -> MMCompat.m hängt sie beim Start ein, wo sie fehlen.
// Die Neudeklaration ohne Verfügbarkeits-Attribut sagt clang, dass sie ab 5.0 da sind.
@interface NSDictionary (MMCompat)
- (id)objectForKeyedSubscript:(id)key;
@end
@interface NSMutableDictionary (MMCompat)
- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key;
@end
@interface NSArray (MMCompat)
- (id)objectAtIndexedSubscript:(NSUInteger)idx;
@end
@interface NSMutableArray (MMCompat)
- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx;
@end

// Reine Compile-Zeit-Konstanten: die NS*-Werte sind auf iOS identisch mit den UITextAlignment-/UILineBreakMode-Werten von iOS 5
// (Left 0, Center 1, Right 2; WordWrap 0, TailTruncation 4) -> zur Laufzeit gleich, nur das Attribut stört.
// (Auch der Typname NSTextAlignment ist als "ab 6.0" markiert, daher reine Zahlen.)
#define NSTextAlignmentCenter       1
#define NSTextAlignmentRight        2
#define NSLineBreakByWordWrapping   0
#define NSLineBreakByTruncatingTail 4

// Für Stellen, die iOS-6-APIs selbst zur Laufzeit prüfen (respondsToSelector / Symbol != NULL), was clang nicht erkennt.
#define MM_IOS6_BEGIN _Pragma("clang diagnostic push") _Pragma("clang diagnostic ignored \"-Wunguarded-availability\"")
#define MM_IOS6_END   _Pragma("clang diagnostic pop")
#endif
