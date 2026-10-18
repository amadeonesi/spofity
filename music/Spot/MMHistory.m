#import "MMHistory.h"
#import "MMSpotify.h"

#define MAX_TRACKS 50
#define MAX_CONTEXTS 20

@implementation MMHistory
static NSString* file(void){ return MMPath(@"history.plist"); }
+ (long long)nowMs { return (long long)([[NSDate date] timeIntervalSince1970]*1000); }
+ (NSMutableDictionary *)read {
    NSDictionary*d=[NSDictionary dictionaryWithContentsOfFile:file()];
    return [@{@"tracks":[d[@"tracks"] isKindOfClass:[NSArray class]]?d[@"tracks"]:@[],
              @"contexts":[d[@"contexts"] isKindOfClass:[NSArray class]]?d[@"contexts"]:@[]} mutableCopy];
}
// Eintrag nach vorn (älteren gleichen entfernen), Liste kürzen, speichern, Bescheid geben
+ (void)put:(NSDictionary *)e into:(NSString *)key same:(BOOL(^)(NSDictionary*))same max:(NSUInteger)max {
    @synchronized(self){
        NSMutableDictionary*d=[self read]; NSMutableArray*a=[d[key] mutableCopy];
        for(NSInteger i=(NSInteger)a.count-1;i>=0;i--) if(![a[i] isKindOfClass:[NSDictionary class]] || same(a[i])) [a removeObjectAtIndex:i];
        NSMutableDictionary*n=[NSMutableDictionary dictionary];
        for(NSString*k in e) if(![e[k] isKindOfClass:[NSNull class]]) n[k]=e[k];   // plist verträgt kein NSNull
        n[@"at"]=@([self nowMs]); [a insertObject:n atIndex:0];
        while(a.count>max) [a removeLastObject];
        d[key]=a; [d writeToFile:file() atomically:YES];
    }
    dispatch_async(dispatch_get_main_queue(), ^{ [[NSNotificationCenter defaultCenter] postNotificationName:MMHistoryChanged object:nil]; });
}
+ (void)recordTrack:(NSDictionary *)t {
    NSString*tid=t[@"id"]; if(![tid isKindOfClass:[NSString class]]||!tid.length) return;
    [self put:t into:@"tracks" same:^BOOL(NSDictionary*x){ return [x[@"id"] isEqual:tid]; } max:MAX_TRACKS];
}
+ (void)recordContext:(NSDictionary *)c {
    NSString*type=c[@"type"]; if(![type isKindOfClass:[NSString class]]) return;
    [self put:c into:@"contexts" same:^BOOL(NSDictionary*x){ return [x[@"type"] isEqual:type] && ([type isEqualToString:@"liked"] || [x[@"id"] isEqual:c[@"id"]]); } max:MAX_CONTEXTS];
}
+ (NSArray *)tracks { @synchronized(self){ return [self read][@"tracks"]; } }
+ (NSArray *)contexts { @synchronized(self){ return [self read][@"contexts"]; } }
@end
