// iOS 5: Subscripting-Methoden nachrüsten (siehe MMCompat.h). Auf iOS 6 sind alle vorhanden, dann passiert hier nichts.
// +load läuft vor jedem anderen Code der App (MMCompat steht beim Linken vor MMDebug, dem einzigen anderen +load mit Inhalt).
#import <objc/runtime.h>

static id dictGet(NSDictionary *self, SEL _cmd, id key) { return [self objectForKey:key]; }
static void dictSet(NSMutableDictionary *self, SEL _cmd, id obj, id key) {
    if (obj) [self setObject:obj forKey:key]; else [self removeObjectForKey:key];   // wie iOS 6: d[k]=nil entfernt den Schlüssel
}
static id arrGet(NSArray *self, SEL _cmd, NSUInteger i) { return [self objectAtIndex:i]; }
static void arrSet(NSMutableArray *self, SEL _cmd, id obj, NSUInteger i) {
    if (i == self.count) [self addObject:obj]; else [self replaceObjectAtIndex:i withObject:obj];   // wie iOS 6: a[count]=x hängt an
}

static void add(Class c, SEL s, IMP imp, const char *types) {
    if (![c instancesRespondToSelector:s]) class_addMethod(c, s, imp, types);
}

@interface MMCompat : NSObject
@end
@implementation MMCompat
+ (void)load {
    add([NSDictionary class], @selector(objectForKeyedSubscript:), (IMP)dictGet, "@@:@");
    add([NSMutableDictionary class], @selector(setObject:forKeyedSubscript:), (IMP)dictSet, "v@:@@");
    add([NSArray class], @selector(objectAtIndexedSubscript:), (IMP)arrGet, "@@:I");
    add([NSMutableArray class], @selector(setObject:atIndexedSubscript:), (IMP)arrSet, "v@:@I");
}
@end
