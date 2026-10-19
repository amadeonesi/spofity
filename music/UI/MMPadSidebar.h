// MMPadSidebar.h - iPad: Seitenleiste links (Home, Browse, Search, Library, Playlists, Cover Flow, Einstellungen), wie Spotify 2012.
#import <UIKit/UIKit.h>
@interface MMPadSidebar : UIView
// Schlüssel: home, browse, search, library, liked, playlist:<id>, coverflow, settings
@property (nonatomic, copy) void (^onSelect)(NSString *key);
- (void)setSelectedKey:(NSString *)key;     // Zeile hervorheben (nil = keine)
- (void)reloadPlaylists;                    // eigene Playlists (alle Seiten) neu laden
- (NSString *)nameForKey:(NSString *)key;   // Anzeigename (z. B. Playlist-Titel für die Titelliste)
// Cover des laufenden Titels groß unten in der Leiste (über Playlists, Cover Flow, Einstellungen); Pfeil nach unten schickt es zurück
@property (nonatomic, copy) void (^onCoverBack)(void);
- (void)showCover:(NSString *)url animated:(BOOL)animated;   // auch zum Aktualisieren bei neuem Titel
- (void)hideCoverAnimated:(BOOL)animated;
- (void)setShowsCoverFlow:(BOOL)on;   // Einstellung "Cover Flow": Eintrag ein-/ausblenden
@end
