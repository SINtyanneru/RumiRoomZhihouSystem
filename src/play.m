#import <Foundation/Foundation.h>
#import <stdint.h>
#import <alsa/asoundlib.h>

BOOL play_pcm(NSData *pcm_data, uint8_t ch, uint32_t rate, snd_pcm_format_t format, char *device) {
	int32_t byte_par_sample = snd_pcm_format_physical_width(format) / 8;
	if (byte_par_sample <= 0 || ch == 0) return NO;

	size_t frame_byte = (size_t)ch * (size_t)byte_par_sample;
	snd_pcm_uframes_t remain = [pcm_data length] / frame_byte;
	const uint8_t *p = [pcm_data bytes];

	snd_pcm_t *pcm = NULL;
	if (snd_pcm_open(&pcm, device, SND_PCM_STREAM_PLAYBACK, 0) < 0) return NO;

	if (snd_pcm_set_params(pcm, format, SND_PCM_ACCESS_RW_INTERLEAVED, ch, rate, 1, 500000) < 0) return NO;

	while (remain > 0) {
		snd_pcm_sframes_t n = snd_pcm_writei(pcm, p, remain);
		if (n < 0) {
			n = snd_pcm_recover(pcm, (int)n, 1);
			if (n < 0) {
				NSLog(@"snd_pcm_writei: %s", snd_strerror((int)n));
				break;
			}
			continue;
		}
		p += (size_t)n * frame_byte;
		remain -= (snd_pcm_uframes_t)n;
	}

	snd_pcm_drain(pcm);
	snd_pcm_close(pcm);

	return YES;
}