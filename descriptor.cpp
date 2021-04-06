#include <stdio.h>

extern "C" int get_descriptor(FILE* fp){
    return fileno(fp);
}