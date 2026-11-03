/**
 * アルゴリズムはClaudeに考えさせた
*/
#import "stdbool.h"
#import <Foundation/Foundation.h>
#import <stddef.h>
#import <math.h>
#import <stdint.h>
#import <stdio.h>
#import <stdlib.h>
#import <string.h>
#import "sound.h"
#import "const.h"

//PCMデータのフレーム数
static uint64_t frame(NSData *pcm) {
	return (uint64_t)([pcm length] / FRAME_BYTES);
}

//正弦波をPCMデータに追記する
static void write_tone(NSMutableData *buffer, double freq, double sec) {
	uint64_t n = (uint64_t)( SR * sec );
	double fade = SR * 0.005;

	for (uint64_t i = 0; i < n; i++) {
		double env = fmin(1.0, fmin(i, n - 1 - i) / fade);
		int16_t s = (int16_t)( sin(2 * M_PI * freq * i / SR) * env * 12000 );
		int16_t lr[2] = { s, s };
		[buffer appendBytes:lr length:FRAME_BYTES];
	}
}

//フェードアウト付き正弦波をPCMデータに追記する
static void write_fadeout_tone(NSMutableData *buffer, double freq, double sec, double fade_sec) {
	uint64_t n = (uint64_t)( SR * sec );
	uint64_t fade_n = (uint64_t)( SR * fade_sec );

	if (fade_n > n) fade_n = n;

	uint64_t fade_start = n - fade_n;
	double attack = SR * 0.005;

	for (uint64_t i = 0; i < n; i++) {
		double env = fmin(1.0, i / attack);
		if (i >= fade_start) {
			double t = (double)( i - fade_start ) / fade_n;
			env *= 0.5 * ( 1.0 + cos(M_PI * t) );
		}

		int16_t s = (int16_t)( sin(2 * M_PI * freq * i / SR) * env * 12000 );
		int16_t lr[2] = { s, s };
		[buffer appendBytes:lr length:FRAME_BYTES];
	}
}

//重ね合わせ
static void mix(NSMutableData *dst, NSData *src, uint64_t offset_frame, double gain) {
	int16_t *d = (int16_t *)[dst mutableBytes];
	const int16_t *s = (const int16_t *)[src bytes];
	uint64_t dn = frame(dst);
	uint64_t sn = frame(src);

	for (uint64_t i = 0; i < sn && offset_frame + i < dn; i++) {
		for (uint64_t c = 0; c < CH; c++) {
			uint64_t idx = (offset_frame + i) * CH + c;
			int32_t v = d[idx] + (int32_t)(s[i * CH + c] * gain);

			if (v > 32767) v = 32767;
			if (v < -32768) v = -32768;
			d[idx] = (int16_t)v;
		}
	}
}

//ダッキング(音量を自然に下げるやつ)
static void ducking(NSMutableData *pcm, uint64_t start_frame, uint64_t end_frame, double duck_gain, double attack_sec, double release_sec) {
	int16_t *d = (int16_t *)[pcm mutableBytes];
	int n = frame(pcm);
	int attack_n = (int)(SR * attack_sec);
	int release_n = (int)(SR * attack_sec);
	if (attack_n < 1) attack_n = 1;
	if (release_n < 1) release_n = 1;

	int from = start_frame - attack_n;
	int to = end_frame + release_n;
	if (from < 0) from = 0;
	if (to > n) to = n;

	for (int i = from; i < to; i++) {
		double w;
		if (i < start_frame) {
			double t = (double)(i - (start_frame - attack_n)) / attack_n;
			w = 0.5 * (1.0 - cos(M_PI * t));
		} else if (i < end_frame) {
			w = 1.0;
		} else {
			double t = (double)(i - end_frame) / release_n;
			w = 0.5 * (1.0 + cos(M_PI * t));
		}
		double g = 1.0 - (1.0 - duck_gain) * w;
		for (int c = 0; c < CH; c++) {
			d[i * CH + c] = (int16_t)(d[i * CH + c] * g);
		}
	}
}

static uint16_t read_16(const uint8_t *p) {
	return (uint16_t)(p[0] | (p[1] << 8));
}
static uint32_t read_32(const uint8_t *p) {
	return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

static void write_16(NSMutableData *d, uint16_t v) {
	uint8_t b[2] = { (uint8_t)(v & 0xFF), (uint8_t)((v >> 8) & 0xFF) };
	[d appendBytes:b length:2];
}
static void write_32(NSMutableData *d, uint32_t v) {
	uint8_t b[4] = { (uint8_t)(v & 0xFF), (uint8_t)((v >> 8) & 0xFF), (uint8_t)((v >> 16) & 0xFF), (uint8_t)((v >> 24) & 0xFF) };
	[d appendBytes:b length:4];
}

static NSData *parse_wav(NSData *data) {
	const uint8_t *b = [data bytes];
	NSUInteger length = [data length];
	if (memcmp(b, "RIFF", 4) != 0 || memcmp(b + 8, "WAVE", 4) != 0) {
		fprintf(stderr, "WAVではありません\n");
		return nil;
	}

	BOOL got_fmt = NO;
	uint16_t in_ch = 0;
	uint32_t in_rate = 0;
	NSUInteger pos = 12;
	while (pos + 8 <= length) {
		uint32_t size = read_32(b + pos + 4);
		const uint8_t *body = b + pos + 8;

		if (memcmp(b + pos, "fmt ", 4) == 0 && size >= 16 && pos + 8 + size <= length) {
			uint16_t format = read_16(body);       //1=PCM, 0xFFFE=拡張
			in_ch = read_16(body + 2);
			in_rate = read_32(body + 4);
			uint16_t bit = read_16(body + 14);
			if (format != 1 && format != 0xFFFE) {
				fprintf(stderr, "PCMではありません\n");
				return nil;
			}
			if ((in_ch != 1 && in_ch != 2) || bit != 16 || in_rate == 0) {
				fprintf(stderr, "非対応の形式です(ch=%u rate=%u bits=%u)\n", in_ch, in_rate, bit);
				return nil;
			}
			got_fmt = YES;
		} else if (memcmp(b + pos, "data", 4) == 0) {
			if (!got_fmt) return nil;
			//サイズが壊れている・ストリーム出力で0xFFFFFFFFの場合は、残り全部を使う
			NSUInteger avail = length - (pos + 8);
			NSUInteger n = (size > avail) ? avail : size;
			int in_frames = (int)(n / (in_ch * 2));
			if (in_frames < 1) return nil;

			//出力フレーム数(44100Hzに換算)
			int out_frames = (int)((int64_t)in_frames * SR / in_rate);
			NSMutableData *out = [NSMutableData dataWithLength:(NSUInteger)out_frames * FRAME_BYTES];
			int16_t *o = (int16_t *)[out mutableBytes];

			for (int i = 0; i < out_frames; i++) {
				//出力iフレーム目に対応する入力側の位置(線形補間)
				double src = (double)i * in_rate / SR;
				int i0 = (int)src;
				double frac = src - i0;
				int i1 = (i0 + 1 < in_frames) ? i0 + 1 : in_frames - 1;
				if (i0 >= in_frames) i0 = in_frames - 1;

				for (int c = 0; c < CH; c++) {
					//モノラルなら両チャンネルに同じ音を入れる
					int sc = (in_ch == 1) ? 0 : c;
					int16_t a = (int16_t)read_16(body + ((size_t)i0 * in_ch + sc) * 2);
					int16_t d = (int16_t)read_16(body + ((size_t)i1 * in_ch + sc) * 2);
					o[i * CH + c] = (int16_t)(a + (d - a) * frac);
				}
			}
			return out;
		}

		//チャンクは偶数バイト境界にパディングされる
		pos += 8 + (NSUInteger)size + (size & 1);
	}
	fprintf(stderr, "dataチャンクが見つかりません\n");
	return nil;
}

static NSData *build_announce(uint8_t hour) {
	NSMutableData *out = [NSMutableData data];

	NSData *prefix = parse_wav(load_sound_prefix());
	[out appendData:prefix];

	if (hour != 12) {
		if (hour < 12) {
			NSData *voice = parse_wav(load_sound_am());
			[out appendData:voice];
		} else {
			NSData *voice = parse_wav(load_sound_pm());
			[out appendData:voice];
		}
	}

	NSData *hour_voice = parse_wav(load_sound_time( ( (hour + 11) % 12 ) + 1 ));
	[out appendData:hour_voice];

	NSData *sufix = parse_wav(load_sound_sufix());
	[out appendData:sufix];

	return out;
}

BOOL save_wav(NSString *path, NSData *pcm) {
	uint32_t data_size = (uint32_t)[pcm length];
	NSMutableData *out = [NSMutableData dataWithCapacity:44 + data_size];

	[out appendBytes:"RIFF" length:4];
	write_32(out, 36 + data_size);
	[out appendBytes:"WAVE" length:4];

	[out appendBytes:"fmt " length:4];
	write_32(out, 16);
	write_16(out, 1);
	write_16(out, CH);
	write_32(out, SR);
	write_32(out, SR * FRAME_BYTES);
	write_16(out, FRAME_BYTES);
	write_16(out, 16);

	[out appendBytes:"data" length:4];
	write_32(out, data_size);
	[out appendData:pcm];

	if (![out writeToFile:path atomically:YES]) {
		return NO;
	}
	return YES;
}

NSData *gen(uint8_t hour, NSString *out_path) {
	//素材読み込み
	NSData *bgm = nil;
	NSData *voice = build_announce(hour);

	if (hour >= 6 && hour <= 17) {
		bgm = parse_wav(load_sound_bgm_a());
	} else {
		bgm = parse_wav(load_sound_bgm_b());
	}

	//BGMを土台にして、読み上げを1.5秒後から重ねる
	int voice_offset = SR * 1.5;
	NSMutableData *pcm = [NSMutableData dataWithData:bgm];
	ducking(pcm, voice_offset, voice_offset + frame(voice), 0.25, 0.3, 0.6);
	mix(pcm, voice, voice_offset, 1.0);

	//ポーンの開始位置 = BGMの終端
	int po_offset = frame(pcm);
	if (po_offset < SR * 3) {
		return nil;
	}

	//読み上げがピに被る場合は警告
	int voice_end = voice_offset + frame(voice);
	if (voice_end > po_offset - SR * 3) {
		return nil;
	}

	//ピ(440Hz 0.1秒)を、ポーンの2秒前と1秒前に重ねる
	NSMutableData *pi = [NSMutableData data];
	write_tone(pi, 440, 0.1);
	mix(pcm, pi, po_offset - SR * 3, 1.0);
	mix(pcm, pi, po_offset - SR * 2, 1.0);
	mix(pcm, pi, po_offset - SR * 1, 1.0);

	//ポーン(880Hz)をBGMの直後に足す
	write_fadeout_tone(pcm, 880, ZHIHOU_POON_SEC, 1.0);

	return pcm;
}