// MMRecent.h - zuletzt gehörte Playlists (Spotifys Verlauf + Wiedergaben in dieser App, nach Zeit gemischt) und Artist-Bilder.
// Für die iPad-Seitenleiste ("Recent Playlists") und die Startseite.
#import <Foundation/Foundation.h>
@interface MMRecent : NSObject
// [{id,name,cover}] neueste zuerst, höchstens max. done kann zweimal kommen (erst gespeichert, dann frisch) und kommt auf Main.
+ (void)playlists:(NSUInteger)max done:(void(^)(NSArray *list))done;
// Bild eines Artists (URL, nil wenn keins); aus dem Speicher sofort, sonst einmal laden (artists/<id>, gespeichert).
+ (void)artistImage:(NSString *)artistId done:(void(^)(NSString *url))done;
@end
