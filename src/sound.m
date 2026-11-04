#pragma clang diagnostic ignored "-Wc23-extensions"
#import <Foundation/Foundation.h>
#import <stdint.h>

//BGM A
static const uint8_t sound_bgm_a[] = {
	#embed "../sound/bgm_a.wav"
};

//BGM B
static const uint8_t sound_bgm_b[] = {
	#embed "../sound/bgm_b.wav"
};

//prefix 「るみさんのお部屋が」
static const uint8_t sound_prefix[] = {
	#embed "../sound/prefix.wav"
};

//sufix 「を、お知らせします」
static const uint8_t sound_sufix[] = {
	#embed "../sound/sufix.wav"
};

//午前
static const uint8_t sound_am[] = {
	#embed "../sound/am.wav"
};

//午後
static const uint8_t sound_pm[] = {
	#embed "../sound/pm.wav"
};

//時刻
static const uint8_t sound_time_0[] = {
	#embed "../sound/time/0.wav"
};

static const uint8_t sound_time_1[] = {
	#embed "../sound/time/1.wav"
};

static const uint8_t sound_time_2[] = {
	#embed "../sound/time/2.wav"
};

static const uint8_t sound_time_3[] = {
	#embed "../sound/time/3.wav"
};

static const uint8_t sound_time_4[] = {
	#embed "../sound/time/4.wav"
};

static const uint8_t sound_time_5[] = {
	#embed "../sound/time/5.wav"
};

static const uint8_t sound_time_6[] = {
	#embed "../sound/time/6.wav"
};

static const uint8_t sound_time_7[] = {
	#embed "../sound/time/7.wav"
};

static const uint8_t sound_time_8[] = {
	#embed "../sound/time/8.wav"
};

static const uint8_t sound_time_9[] = {
	#embed "../sound/time/9.wav"
};

static const uint8_t sound_time_10[] = {
	#embed "../sound/time/0.wav"
};

static const uint8_t sound_time_11[] = {
	#embed "../sound/time/11.wav"
};

static const uint8_t sound_time_12[] = {
	#embed "../sound/time/s.wav"
};

static NSData *load_embeded_data(const uint8_t *embed, size_t length) {
	return [NSData dataWithBytesNoCopy:(void *)embed length:length freeWhenDone:NO];
}

NSData *load_sound_bgm_a() {
	return load_embeded_data(sound_bgm_a, sizeof(sound_bgm_a));
}

NSData *load_sound_bgm_b() {
	return load_embeded_data(sound_bgm_b, sizeof(sound_bgm_b));
}

NSData *load_sound_prefix() {
	return load_embeded_data(sound_prefix, sizeof(sound_prefix));
}

NSData *load_sound_sufix() {
	return load_embeded_data(sound_sufix, sizeof(sound_sufix));
}

NSData *load_sound_am() {
	return load_embeded_data(sound_am, sizeof(sound_am));
}

NSData *load_sound_pm() {
	return load_embeded_data(sound_pm, sizeof(sound_pm));
}

NSData *load_sound_time(uint8_t hour) {
	switch (hour) {
		case 0:
			return load_embeded_data(sound_time_0, sizeof(sound_time_0));
		case 1:
			return load_embeded_data(sound_time_1, sizeof(sound_time_1));
		case 2:
			return load_embeded_data(sound_time_2, sizeof(sound_time_2));
		case 3:
			return load_embeded_data(sound_time_3, sizeof(sound_time_3));
		case 4:
			return load_embeded_data(sound_time_4, sizeof(sound_time_4));
		case 5:
			return load_embeded_data(sound_time_5, sizeof(sound_time_5));
		case 6:
			return load_embeded_data(sound_time_6, sizeof(sound_time_6));
		case 7:
			return load_embeded_data(sound_time_7, sizeof(sound_time_7));
		case 8:
			return load_embeded_data(sound_time_8, sizeof(sound_time_8));
		case 9:
			return load_embeded_data(sound_time_9, sizeof(sound_time_9));
		case 10:
			return load_embeded_data(sound_time_10, sizeof(sound_time_10));
		case 11:
			return load_embeded_data(sound_time_11, sizeof(sound_time_11));
		case 12:
			return load_embeded_data(sound_time_12, sizeof(sound_time_12));

		default:
			return load_embeded_data(sound_time_0, sizeof(sound_time_0));
	}
}