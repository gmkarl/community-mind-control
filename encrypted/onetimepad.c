// modified from https://github.com/luiguip/one-time-pad-for-linux/blob/master/one_time_pad.c
#include<stdio.h>
#include<unistd.h>
#define CIPHER(x,y) {x^=y;}

int main(int argc, char** argv){
	char mode[] = "rb";
	char wmode[] = "wb";
	int element;
	int key;
	fpos_t pos;
	if(argc<4){
		printf("Error: Missing arguments\n");
		return(-1);
	}
	FILE* file=fopen(argv[1],mode);
	FILE* pswd=fopen(argv[2],mode);
        FILE* pout=fopen(argv[3],wmode);
	if(!file || !pswd || !pout){
		perror("Error: ");
		return(-1);
	}
	while(fread(&element,1,1,file)==1){
		key=fgetc(pswd);
		CIPHER(element,key);
		fputc(element,stdout);
		fputc(key,pout);
	}
	fclose(file);
	fclose(pswd);
	fclose(pout);
	return 0;
}


