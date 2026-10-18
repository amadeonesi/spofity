#import "MMAudio.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <mach/mach_time.h>
#import <sys/resource.h>
#import "MMSpotify.h"

// stb_vorbis direkt einbinden (kein separates Kompilat -> keine Doppel-Symbole).
#define STB_VORBIS_NO_STDIO
#define STB_VORBIS_NO_PUSHDATA_API
#include "stb_vorbis.c"

#define NUMBUF 3
#define BUFFRAMES 8192   // Frames pro Puffer

static AudioQueueRef gAQ=NULL;
static stb_vorbis *gV=NULL;
static NSData *gOgg=nil;        // festhalten: stb_vorbis liest direkt aus diesem Speicher
static int gCh=2;
static double gSampleRate=44100.0, gDuration=0.0, gBaseTime=0.0;
static BOOL gRunning=NO, gPaused=NO;

// ---- CPU-Messung (3GS): Dekodierzeit im Verhältnis zur erzeugten Audiodauer + CPU des ganzen Prozesses.
// Alle 30 s Audio eine Zeile ins App-Log. decode 25% = Vorbis braucht ein Viertel eines Kerns.
#define CPU_WINDOW 30.0
static double gDecSec=0, gAudSec=0, gWall0=0, gCpu0=0;
static double nowSec(void){ static mach_timebase_info_data_t tb; if(!tb.denom) mach_timebase_info(&tb); return (double)mach_absolute_time()*tb.numer/tb.denom/1e9; }
static double procCpuSec(void){ struct rusage r; getrusage(RUSAGE_SELF,&r);
    return r.ru_utime.tv_sec+r.ru_utime.tv_usec/1e6+r.ru_stime.tv_sec+r.ru_stime.tv_usec/1e6; }
static void cpuReset(void){ gDecSec=0; gAudSec=0; gWall0=nowSec(); gCpu0=procCpuSec(); }
static void cpuAccount(double dec, int frames){
    gDecSec+=dec; gAudSec+=frames/(gSampleRate>0?gSampleRate:44100.0);
    if(gAudSec<CPU_WINDOW) return;
    double wall=nowSec()-gWall0, cpu=procCpuSec()-gCpu0;
    MMLog(@"cpu: decode %.1f%% of realtime, process %.1f%% (%.0f s audio, %.0f s wall, %d ch, %.0f Hz)",
          100*gDecSec/gAudSec, wall>0?100*cpu/wall:0, gAudSec, wall, gCh, gSampleRate);
    cpuReset();
}

static void fillCb(void *ud, AudioQueueRef q, AudioQueueBufferRef buf){
    if(!gV || !gRunning){ buf->mAudioDataByteSize=0; return; }
    short *out=(short*)buf->mAudioData;
    int capShorts=buf->mAudioDataBytesCapacity/(int)sizeof(short);
    double t0=nowSec();
    int got=stb_vorbis_get_samples_short_interleaved(gV,gCh,out,capShorts); // got = Frames pro Kanal
    if(got>0) cpuAccount(nowSec()-t0,got);
    if(got<=0){ // Ende
        buf->mAudioDataByteSize=0;
        gRunning=NO;
        AudioQueueStop(q,false);  // asynchron auslaufen lassen
        dispatch_async(dispatch_get_main_queue(), ^{   // Track zu Ende -> Auto-Advance
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MMAudioDidFinish" object:nil];
        });
        return;
    }
    buf->mAudioDataByteSize=got*gCh*(int)sizeof(short);
    AudioQueueEnqueueBuffer(q,buf,0,NULL);
}

@implementation MMAudio

+ (void)playOgg:(NSData *)ogg {
    [self stop];
    if(ogg.length<=167) return;
    // Playback-Session: spielt auch bei Stummschalter & im Hintergrund/gesperrt weiter
    AVAudioSession*as=[AVAudioSession sharedInstance];
    [as setCategory:AVAudioSessionCategoryPlayback error:NULL];
    [as setActive:YES error:NULL];
    gOgg=ogg;
    int err=0;
    gV=stb_vorbis_open_memory((const unsigned char*)ogg.bytes+167,(int)ogg.length-167,&err,NULL);
    if(!gV){ gOgg=nil; return; }
    stb_vorbis_info info=stb_vorbis_get_info(gV);
    gCh=info.channels>0?info.channels:2;
    gSampleRate=info.sample_rate>0?info.sample_rate:44100.0;
    gDuration=stb_vorbis_stream_length_in_seconds(gV);
    gBaseTime=0; cpuReset();

    AudioStreamBasicDescription a; memset(&a,0,sizeof(a));
    a.mSampleRate=info.sample_rate;
    a.mFormatID=kAudioFormatLinearPCM;
    a.mFormatFlags=kAudioFormatFlagIsSignedInteger|kAudioFormatFlagIsPacked;
    a.mBitsPerChannel=16;
    a.mChannelsPerFrame=gCh;
    a.mFramesPerPacket=1;
    a.mBytesPerFrame=2*gCh;
    a.mBytesPerPacket=2*gCh;

    gRunning=YES; gPaused=NO;
    if(AudioQueueNewOutput(&a,fillCb,NULL,NULL,NULL,0,&gAQ)!=0){ [self stop]; return; }
    for(int i=0;i<NUMBUF;i++){
        AudioQueueBufferRef b=NULL;
        AudioQueueAllocateBuffer(gAQ,BUFFRAMES*2*gCh,&b);
        fillCb(NULL,gAQ,b);
    }
    AudioQueueStart(gAQ,NULL);
}

+ (void)stop {
    gRunning=NO;
    if(gAQ){ AudioQueueStop(gAQ,true); AudioQueueDispose(gAQ,true); gAQ=NULL; }
    if(gV){ stb_vorbis_close(gV); gV=NULL; }
    gOgg=nil; gPaused=NO;
}

+ (void)setPaused:(BOOL)paused {
    if(!gAQ) return;
    gPaused=paused;
    if(paused) AudioQueuePause(gAQ); else { cpuReset(); AudioQueueStart(gAQ,NULL); }
}

+ (BOOL)isPlaying { return gRunning && !gPaused; }
+ (BOOL)hasEnded { return gAQ!=NULL && !gRunning; }   // Titel bis zum Ende gespielt (Queue gestoppt, aber noch geladen)
+ (BOOL)isLoaded { return gAQ!=NULL; }                 // NO = nichts geladen (gestoppt) -> "Weiter" hätte nichts zum Fortsetzen

+ (double)duration { return gDuration; }

+ (double)currentTime {
    if(!gAQ) return gBaseTime;
    AudioTimeStamp ts; memset(&ts,0,sizeof(ts));
    OSStatus r=AudioQueueGetCurrentTime(gAQ,NULL,&ts,NULL);
    double t=gBaseTime;
    if(r==0 && (ts.mFlags & kAudioTimeStampSampleTimeValid)) t+=ts.mSampleTime/(gSampleRate>0?gSampleRate:44100.0);
    if(t<0) t=0; if(gDuration>0 && t>gDuration) t=gDuration;
    return t;
}

+ (void)seekTo:(double)seconds {
    if(!gV) return;
    if(seconds<0)seconds=0; if(gDuration>0&&seconds>gDuration)seconds=gDuration;
    if(gAQ){ AudioQueueStop(gAQ,true); AudioQueueDispose(gAQ,true); gAQ=NULL; }
    stb_vorbis_seek(gV,(unsigned int)(seconds*gSampleRate));
    gBaseTime=seconds; gRunning=YES; gPaused=NO; cpuReset();
    AudioStreamBasicDescription a; memset(&a,0,sizeof(a));
    a.mSampleRate=gSampleRate; a.mFormatID=kAudioFormatLinearPCM;
    a.mFormatFlags=kAudioFormatFlagIsSignedInteger|kAudioFormatFlagIsPacked;
    a.mBitsPerChannel=16; a.mChannelsPerFrame=gCh; a.mFramesPerPacket=1; a.mBytesPerFrame=2*gCh; a.mBytesPerPacket=2*gCh;
    if(AudioQueueNewOutput(&a,fillCb,NULL,NULL,NULL,0,&gAQ)!=0) return;
    for(int i=0;i<NUMBUF;i++){ AudioQueueBufferRef b=NULL; AudioQueueAllocateBuffer(gAQ,BUFFRAMES*2*gCh,&b); fillCb(NULL,gAQ,b); }
    AudioQueueStart(gAQ,NULL);
}


@end
