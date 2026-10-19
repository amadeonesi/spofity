#import <UIKit/UIKit.h>
@interface MMLibraryController : UIViewController
// Spotify-Playlist-Einträge -> {name,id,cover} (Library-Seite und iPad-Seitenleiste)
+ (NSArray *)parsePlaylists:(NSArray *)items;
@end
