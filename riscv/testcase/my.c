#include "io.h"
int main()
{
    int sum = 0; 
    for (int k = 0; k < 100000; ++k) 
        sum += 1; 
    outlln(sum);
}
