#include "io.h"
int tak(int x, int y, int z) {
  return 1 + x * y * z; 
}

int main(){
	int a = 1;
	int b = 2;
	int c = 3;
	outlln(tak(a,b,c));
	return 0;
}
