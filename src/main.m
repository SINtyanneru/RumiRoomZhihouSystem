#include "objc/objc.h"
#import <Foundation/Foundation.h>
#import <alsa/asoundlib.h>
#import <stdint.h>
#import <time.h>
#import <stdio.h>
#import <getopt.h>
#import "gen.h"
#import "const.h"
#import "play.h"

static void waiting_until(time_t target) {
	struct timespec ts;
	ts.tv_sec = target;
	ts.tv_nsec = 0;
	while (clock_nanosleep(CLOCK_REALTIME, TIMER_ABSTIME, &ts, NULL) == EINTR) {}
}

static time_t next_target(void) {
	time_t now = time(NULL);
	struct tm t;
	localtime_r(&now, &t);

	t.tm_min = 0;
	t.tm_sec = 0;
	t.tm_isdst = -1;
	time_t z = mktime(&t);

	//過ぎていたら次の時間へ
	if (z <= now) {
		t.tm_hour += 1;
		t.tm_isdst = -1;
		z = mktime(&t);
	}
	return z;
}

int main(int argc, char *argv[]) {
	printf("るみ部屋時報システム RRZS\n");

	@autoreleasepool {
		NSString *WAV_PATH = @"/tmp/zhihou.wav";
		BOOL sound_play = YES;

		struct option option_list[] = {
			{ "no-play", no_argument, NULL, 0 }
		};

		int32_t opt;
		while ((opt = getopt_long(argc, argv, "hvo:c:", option_list, NULL)) != -1) {
			switch (opt) {
				case 0: {
					sound_play = NO;
					printf("[ INFO ]音声再生をしません。\n");
					break;
				}
			}
		}

		while (YES) {
			time_t z = next_target();
			time_t z_gen = z - 300;
			time_t z_play = z - 10;
			NSData *pcm = nil;

			//生成開始時刻まで待つ(既に過ぎていれば即生成)
			if (z_gen > time(NULL)) {
				printf("待っています\n");
				waiting_until(z_gen);
			}

			//再生に間に合う場合のみ生成
			if (z_play > time(NULL)) {
				printf("生成中...\n");

				struct tm t;
				localtime_r(&z, &t);
				pcm = gen((uint8_t)t.tm_hour);

				if (pcm == nil || [pcm length] == 0) {
					printf("生成失敗\n");
					pcm = nil;
				} else {
					save_wav(WAV_PATH, pcm);
					printf("生成し、保存しました\n");
				}
			}

			//再生
			if (sound_play) {
				if (pcm != nil && z_play > time(NULL)) {
					waiting_until(z_play);
					printf("再生開始\n");
					play_pcm(pcm, CH, SR, SND_PCM_FORMAT_S16_LE, "default");
					printf("終了\n");
				} else {
					printf("間に合わなかったのでスキップ\n");
				}
			}

			//対象時刻まで待つ(これで次周のnext_targetは必ず次の時間を返す)
			if (z > time(NULL)) {
				printf("次を待っています\n");
				waiting_until(z);
			}
		}
	}

	return 0;
}