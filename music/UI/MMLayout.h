// MMLayout.h - iPad-/iPhone-Weiche und gemeinsame Maße. iPhone: alles wie bisher; iPad: Seitenleiste + Inhalt + Player-Leiste.
#import <UIKit/UIKit.h>

BOOL MMIsPad(void);                       // echtes iPad-Layout (nicht der iPhone-Kompatibilitätsmodus)

#define MMPadSidebarW 220                 // Seitenleiste links, in beiden Ausrichtungen sichtbar
#define MMPadBarH     72                  // Player-Leiste unten, volle Breite
#define MMPadSheetW   480                 // Menüs von unten: begrenzte Breite, mittig (wie die Mitteilungszentrale)
#define MMPadColumnW  400
#define MMTrackRowH   56                  // Titelzeilen in Album-/Playlist-Listen (iPhone und iPad)                 // Anmeldung/Schlüssel: mittige Spalte

// Rahmen für eine neue Seite. iPhone: genau wie bisher (applicationFrame bzw. Bildschirm), iPad: Größe des Inhaltsbereichs.
CGRect MMPageFrame(BOOL belowStatusBar);
// Platz unten in Listen: iPhone für Now-Playing- + Tab-Leiste (phone), iPad nur für die Download-Leiste (24)
CGFloat MMPageBottomInset(CGFloat phone);
// iPad: Autoresizing der direkten Unteransichten aus ihrer Lage ableiten (volle Breite dehnt sich, rechts bündig bleibt rechts,
// mittig bleibt mittig, unten bündig bleibt unten). Schon gesetzte Masken bleiben. iPhone: tut nichts (Größen ändern sich nie).
void MMAutoMask(UIView *page);
// Wiederverwendungs-ID einer Zelle mit der Tabellenbreite: nach dem Drehen entstehen neue Zellen in der neuen Breite
NSString *MMCellID(NSString *base, UITableView *tv);
// Spalten im Kachel-Raster: iPhone 2, iPad hoch 3, quer 4 (eine Kachel ist mindestens ~160 pt breit)
NSInteger MMGridColumns(CGFloat width);

// Seiten, deren Inhalt aus der Breite berechnet wird (Kachel-Raster, Zellen), bauen sich nach dem Drehen hier neu auf.
@protocol MMRelayout <NSObject>
- (void)relayoutForSize:(CGSize)size;
@end

// Drehen: iPad alle Ausrichtungen, iPhone nur hochkant (für Root, Player, Anmeldung …)
BOOL MMShouldAutorotate(UIInterfaceOrientation o);   // iOS 5
NSUInteger MMSupportedOrientations(void);             // iOS 6

// Tab-/Seitenleisten-Symbole (schlichte Linien wie Spotify): home, browse, search, library
UIImage *MMTabIcon(NSString *name, UIColor *c, CGFloat s);
UIImage *MMTintedIcon(NSString *name, UIColor *color);   // Lucide line icon, tinted (for tab/queue buttons)
