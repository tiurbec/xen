#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[])
{
   unsigned char a, b, c;
   unsigned long i;
   if (argc!=2)
   {
      printf("int2mac - converts a value to xen mac address\n\n");
      printf("  Usage: int2mac <value>\n\n");
      exit(0);
   }
   i=atol(argv[1]);
   c=i%256;
   i/=256;
   b=i%256;
   i/=256;
   a=i%256;
   printf("00:16:3e:%02x:%02x:%02x",a,b,c);
}
