#include <stdio.h>

int main()
{
int swapped;
int n, i, k, j, m;
n = 3;
int arr[] = {6,3,9};
m =n;

do{
    swapped =0;
    for(j=0; j<n-1; j++){
         if (arr[j]> arr[j+1]){
             
            int temp; 
            temp= arr[j]; 
            arr[j]= arr[j+1]; 
            arr[j+1] = temp;
            swapped = 1;
        }
    }
    n = n-1;
}while(swapped==1);

return arr[0];
// for(k=0; k<m; k++){
//     printf("%d ", arr[k]);
// }
}

