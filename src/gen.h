#import <Foundation/Foundation.h>
#import <stdint.h>

NSData *gen(uint8_t hour);
BOOL save_wav(NSString *path, NSData *pcm);