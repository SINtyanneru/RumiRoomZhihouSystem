#import <Foundation/Foundation.h>
#import <stdio.h>
#import "gen.h"

int main() {
	printf("るみ部屋時報システム RRZS\n");

	@autoreleasepool {
		gen(12, @"zhihou.wav");
	}

	return 0;
}