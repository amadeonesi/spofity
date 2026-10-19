#import <UIKit/UIKit.h>
// Warteschlange: läuft gerade + als Nächstes (aus dem Player geöffnet). Antippen springt zu dem Titel.
@interface MMQueueController : UIViewController
@property (nonatomic, copy) void (^onClose)(void);   // iPad quer: als Spalte rechts eingebettet -> "Fertig" schließt die Spalte
- (void)reload;                                      // neu laden (eingebettet nach jedem Titelwechsel)
@end
