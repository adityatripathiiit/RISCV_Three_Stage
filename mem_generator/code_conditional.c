#include <stdio.h>

int main(void) {
    int a = 100;
    int b = 2;
    int c = a+b;
    if(c>101) {
        c = c+1;
    }
    else{
        return c;
    }
    return c;
}
