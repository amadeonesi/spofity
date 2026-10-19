// MMHistory.h - was auf diesem iPhone gespielt wurde (Spotify kennt diese Wiedergaben nicht: die App meldet sie nicht zurück).
// Die Startseite mischt das nach Zeit mit Spotifys eigenem Verlauf. Gespeichert in Library/Riff/history.plist.
#import <Foundation/Foundation.h>

#define MMHistoryChanged @"MMHistoryChanged"   // Notification nach jeder neuen Wiedergabe

@interface MMHistory : NSObject
+ (void)recordTrack:(NSDictionary *)track;      // {id,title,artist,cover,albumId,album,artistId}
+ (void)recordContext:(NSDictionary *)context;  // {type: playlist|album|artist|liked, id, name, images}
+ (NSArray *)tracks;                            // neueste zuerst, jedes mit "at" (ms seit 1970)
+ (NSArray *)contexts;
+ (long long)nowMs;
@end
