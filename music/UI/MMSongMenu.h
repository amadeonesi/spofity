#import <UIKit/UIKit.h>
// Menü für einen Titel (lange drücken): Artist/Album ansehen, Als Nächstes, Zur Warteschlange, Lieblingssongs an/aus, Zur Playlist hinzufügen.
@interface MMSongMenu : NSObject
+ (void)showForTrack:(NSDictionary *)track;   // track = {id,title,artist,cover}
+ (void)showSaveForTrack:(NSDictionary *)track;   // nur Lieblingssongs + Zur Playlist (der (+)-Knopf im Player)
// Für eine Titelliste: lange drücken = Menü, nach rechts wischen = ans Ende der Warteschlange (swipeToQueue).
// trackAt liefert den Titel zur Zeile (nil = keine Titelzeile).
+ (void)attachToTable:(UITableView *)table swipeToQueue:(BOOL)swipe trackAt:(NSDictionary *(^)(NSIndexPath *ip))trackAt;
// Warteschlange: nach rechts wischen entfernt (rot, Minus-Symbol). remove(ip,NO) fragt, ob die Zeile entfernbar ist; remove(ip,YES) entfernt.
+ (void)attachToTable:(UITableView *)table swipeToRemove:(BOOL(^)(NSIndexPath *ip, BOOL commit))remove trackAt:(NSDictionary *(^)(NSIndexPath *ip))trackAt;
@end
