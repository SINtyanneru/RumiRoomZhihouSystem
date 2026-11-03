#import <Foundation/Foundation.h>
#import <stdint.h>
#import <alsa/asoundlib.h>

BOOL play_pcm(NSData *pcm_data, uint8_t ch, uint32_t rate, snd_pcm_format_t format, char *device);