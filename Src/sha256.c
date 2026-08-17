#include "sha256.h"
#include <string.h>

typedef struct { uint32_t h[8]; uint64_t bits; uint8_t block[64]; size_t used; } ctx_t;
static const uint32_t k[64] = {
0x428a2f98U,0x71374491U,0xb5c0fbcfU,0xe9b5dba5U,0x3956c25bU,0x59f111f1U,0x923f82a4U,0xab1c5ed5U,
0xd807aa98U,0x12835b01U,0x243185beU,0x550c7dc3U,0x72be5d74U,0x80deb1feU,0x9bdc06a7U,0xc19bf174U,
0xe49b69c1U,0xefbe4786U,0x0fc19dc6U,0x240ca1ccU,0x2de92c6fU,0x4a7484aaU,0x5cb0a9dcU,0x76f988daU,
0x983e5152U,0xa831c66dU,0xb00327c8U,0xbf597fc7U,0xc6e00bf3U,0xd5a79147U,0x06ca6351U,0x14292967U,
0x27b70a85U,0x2e1b2138U,0x4d2c6dfcU,0x53380d13U,0x650a7354U,0x766a0abbU,0x81c2c92eU,0x92722c85U,
0xa2bfe8a1U,0xa81a664bU,0xc24b8b70U,0xc76c51a3U,0xd192e819U,0xd6990624U,0xf40e3585U,0x106aa070U,
0x19a4c116U,0x1e376c08U,0x2748774cU,0x34b0bcb5U,0x391c0cb3U,0x4ed8aa4aU,0x5b9cca4fU,0x682e6ff3U,
0x748f82eeU,0x78a5636fU,0x84c87814U,0x8cc70208U,0x90befffaU,0xa4506cebU,0xbef9a3f7U,0xc67178f2U};
static uint32_t rr(uint32_t x,uint32_t n){return (x>>n)|(x<<(32U-n));}
static void transform(ctx_t *c,const uint8_t *p){
 uint32_t w[64],a,b,d,e,f,g,h,t1,t2,cc,i;
 for(i=0;i<16;i++){uint32_t j=i*4U;w[i]=((uint32_t)p[j]<<24)|((uint32_t)p[j+1]<<16)|((uint32_t)p[j+2]<<8)|p[j+3];}
 for(i=16;i<64;i++){uint32_t s0=rr(w[i-15],7)^rr(w[i-15],18)^(w[i-15]>>3);uint32_t s1=rr(w[i-2],17)^rr(w[i-2],19)^(w[i-2]>>10);w[i]=w[i-16]+s0+w[i-7]+s1;}
 a=c->h[0];b=c->h[1];cc=c->h[2];d=c->h[3];e=c->h[4];f=c->h[5];g=c->h[6];h=c->h[7];
 for(i=0;i<64;i++){t1=h+(rr(e,6)^rr(e,11)^rr(e,25))+((e&f)^((~e)&g))+k[i]+w[i];t2=(rr(a,2)^rr(a,13)^rr(a,22))+((a&b)^(a&cc)^(b&cc));h=g;g=f;f=e;e=d+t1;d=cc;cc=b;b=a;a=t1+t2;}
 c->h[0]+=a;c->h[1]+=b;c->h[2]+=cc;c->h[3]+=d;c->h[4]+=e;c->h[5]+=f;c->h[6]+=g;c->h[7]+=h;
}
static void init(ctx_t *c){static const uint32_t iv[8]={0x6a09e667U,0xbb67ae85U,0x3c6ef372U,0xa54ff53aU,0x510e527fU,0x9b05688cU,0x1f83d9abU,0x5be0cd19U};memcpy(c->h,iv,sizeof(iv));c->bits=0;c->used=0;}
static void update(ctx_t *c,const uint8_t *p,size_t n){while(n){size_t m=64U-c->used;if(m>n)m=n;memcpy(c->block+c->used,p,m);c->used+=m;c->bits+=(uint64_t)m*8U;p+=m;n-=m;if(c->used==64U){transform(c,c->block);c->used=0;}}}
static void final(ctx_t *c,uint8_t out[32]){uint64_t bits=c->bits;uint32_t i;c->block[c->used++]=0x80U;if(c->used>56U){memset(c->block+c->used,0,64U-c->used);transform(c,c->block);c->used=0;}memset(c->block+c->used,0,56U-c->used);for(i=0;i<8;i++)c->block[63U-i]=(uint8_t)(bits>>(8U*i));transform(c,c->block);for(i=0;i<8;i++){out[4U*i]=(uint8_t)(c->h[i]>>24);out[4U*i+1]=(uint8_t)(c->h[i]>>16);out[4U*i+2]=(uint8_t)(c->h[i]>>8);out[4U*i+3]=(uint8_t)c->h[i];}}
void sha256(const uint8_t *p,size_t n,uint8_t out[32]){ctx_t c;init(&c);update(&c,p,n);final(&c,out);}
void hmac_sha256(const uint8_t *key,size_t key_n,const uint8_t *msg,size_t msg_n,uint8_t out[32]){
 uint8_t kb[64]={0},ip[64],op[64],inner[32];ctx_t c;size_t i;
 if(key_n>64U)sha256(key,key_n,kb);else memcpy(kb,key,key_n);
 for(i=0;i<64U;i++){ip[i]=(uint8_t)(kb[i]^0x36U);op[i]=(uint8_t)(kb[i]^0x5cU);}
 init(&c);update(&c,ip,64);update(&c,msg,msg_n);final(&c,inner);
 init(&c);update(&c,op,64);update(&c,inner,32);final(&c,out);
}
