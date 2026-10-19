// MMPadPlayerBar.h - iPad: Player-Leiste unten über die ganze Breite (Cover, Titel, Tasten, Fortschritt, Zufall/Wiederholen, Warteschlange).
#import <UIKit/UIKit.h>
@interface MMPadPlayerBar : UIView
- (void)showTitle:(NSString *)title artist:(NSString *)artist coverURL:(NSString *)cover;
- (void)setPlaying:(BOOL)playing loading:(BOOL)loading;
@property (nonatomic, copy) void (^onCoverToSidebar)(void);   // kleiner Pfeil oben rechts am Cover: Cover groß in die Seitenleiste
- (void)setCoverHidden:(BOOL)hidden;
- (void)setLoadProgress:(double)frac;   // Titel lädt: Fortschrittslinie füllt sich grün (frac < 0 = aus)                          // Cover liegt in der Seitenleiste: Titel/Artist rücken nach links
@end
