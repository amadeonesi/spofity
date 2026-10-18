#import <UIKit/UIKit.h>
// Artist-Seite: Bild + Name, beliebteste Titel, Alben und Singles (Antippen öffnet das Album).
@interface MMArtistController : UIViewController
- (id)initWithArtistId:(NSString *)artistId name:(NSString *)name;   // name optional (kommt sonst mit den Daten)
@end
