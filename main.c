/////////////////////////////////////////////////////
// prci-demo - prci demonstration
//
//   SoC clock signal monitor: GPIO19 (LoFive board pin 23), div. by 1000
//   Clock path transition marker: GPIO21 (LoFive board pin 25)
//
//   use gdb to stop/step/start or comment sections in main() as desired.
//
// 1.0  2023-02-23  Paul D. Sherman   initial cut, derived from mram
//

#include <stdint.h>
#include "main.h"

//
// GPIO block
//

#define gpio_base 0x10012000
#define gpio_input_val  (*(volatile uint32_t *) (gpio_base + 0x00))
#define gpio_input_en   (*(volatile uint32_t *) (gpio_base + 0x04))
#define gpio_output_en  (*(volatile uint32_t *) (gpio_base + 0x08))
#define gpio_output_val (*(volatile uint32_t *) (gpio_base + 0x0C))
#define gpio_pue        (*(volatile uint32_t *) (gpio_base + 0x10))
#define gpio_ds         (*(volatile uint32_t *) (gpio_base + 0x14))
#define gpio_rise_ie    (*(volatile uint32_t *) (gpio_base + 0x18))
#define gpio_rise_ip    (*(volatile uint32_t *) (gpio_base + 0x1C))
#define gpio_fall_ie    (*(volatile uint32_t *) (gpio_base + 0x20))
#define gpio_fall_ip    (*(volatile uint32_t *) (gpio_base + 0x24))
#define gpio_high_ie    (*(volatile uint32_t *) (gpio_base + 0x28))
#define gpio_high_ip    (*(volatile uint32_t *) (gpio_base + 0x2C))
#define gpio_low_ie     (*(volatile uint32_t *) (gpio_base + 0x30))
#define gpio_low_ip     (*(volatile uint32_t *) (gpio_base + 0x34))
#define gpio_iof_en     (*(volatile uint32_t *) (gpio_base + 0x38))
#define gpio_iof_sel    (*(volatile uint32_t *) (gpio_base + 0x3C))
#define gpio_passthru_high_ie (*(volatile uint32_t *) (gpio_base + 0x44))
#define gpio_passthru_low_ie  (*(volatile uint32_t *) (gpio_base + 0x48))

#define GPIO0_PWM0_0            0   // LoFive pin 9, 48-QFN pin 25, output from SoC
#define GPIO1_PWM0_1            1   // LoFive pin 10, 48-QFN pin 26, output from SoC
#define GPIO2_PWM0_2_SPI1_SS0   2   // LoFive pin 11, 48-QFN pin 27, output from SoC
#define GPIO3_PWM0_3_SPI1_MOSI  3   // LoFive pin 12, 48-QFN pin 28, output from SoC
#define GPIO4_SPI1_MISO         4   // LoFive pin 13, 48-QFN pin 29, input to SoC
#define GPIO5_SPI1_SCK          5   // LoFive pin 14, 48-QFN pin 31, output from SoC
#define GPIO9_SPI1_SS2          9   // LoFive pin 15, 48-QFN pin 33, output from SoC
#define GPIO10_PWM2_0_SPI1_SS3  10  // LoFive pin 16, 48-QFN pin 34, output from SoC
#define GPIO11_PWM2_1           11  // LoFive pin 17, 48-QFN pin 35, output from SoC
#define GPIO12_PWM2_2           12  // LoFive pin 18, 48-QFN pin 36, output from SoC
#define GPIO13_PWM2_3           13  // LoFive pin 19, 48-QFN pin 37, output from SoC
#define GPIO16_UART0_RX         16  // LoFive pin 20, 48-QFN pin 38, input to SoC
#define GPIO17_UART0_TX         17  // LoFive pin 21, 48-QFN pin 39, output from SoC
#define GPIO18_UART1_TX         18  // LoFive pin 22, 48-QFN pin 40, output from SoC
#define GPIO20_PWM1_0           20  // LoFive pin 24, 48-QFN pin 42, output from SoC
#define GPIO19_PWM1_1           19  // LoFive pin 23, 48-QFN pin 41, output from SoC
#define GPIO21_PWM1_2           21  // LoFive pin 25, 48-QFN pin 43, output from SoC
#define GPIO22_PWM1_3           22  // LoFive pin 26, 48-QFN pin 44, output from SoC
#define GPIO23_UART1_RX         23  // LoFive pin 27, 48-QFN pin 45, input to SoC

//
// AON block
//

#define aon_base 0x10000000
#define aon_rtccfg      (*(volatile uint32_t *) (aon_base + 0x040))
#define aon_rtccountlo  (*(volatile uint32_t *) (aon_base + 0x048))
#define aon_rtccounthi  (*(volatile uint32_t *) (aon_base + 0x04C))
#define aon_rtcs        (*(volatile uint32_t *) (aon_base + 0x050))
#define aon_rtccmp0     (*(volatile uint32_t *) (aon_base + 0x060))

#define aon_wdogcfg      (*(volatile uint32_t *) (aon_base + 0x000))
#define aon_wdogcount    (*(volatile uint32_t *) (aon_base + 0x008))
#define aon_wdogs        (*(volatile uint32_t *) (aon_base + 0x010))
#define aon_wdogfeed     (*(volatile uint32_t *) (aon_base + 0x018))
#define aon_wdogkey      (*(volatile uint32_t *) (aon_base + 0x01C))
#define aon_wdogcmp0     (*(volatile uint32_t *) (aon_base + 0x020))

#define AON_RTCCFG_IP0         0x10000000  // [28]
#define AON_RTCCFG_ENALWAYS    0x00001000  // [12]

#define AON_WDOGCFG_IP0        0x10000000  // [28]
#define AON_WDOGCFG_COREAWAKE  0x00002000  // [13]
#define AON_WDOGCFG_ENALWAYS   0x00001000  // [12]
#define AON_WDOGCFG_ZEROCMP    0x00000200  // [9]
#define AON_WDOGCFG_RSTEN      0x00000100  // [8]
#define AON_WDOGCFG_KEY        0x0051F15E
#define AON_WDOGCFG_FOOD       0x0D09F00D

//
// PWM block
//

#define pwm0_base 0x10015000
#define pwm1_base 0x10025000
#define pwm2_base 0x10035000

#define pwm0_cfg    (*(volatile uint32_t *) (pwm0_base + 0x00))
#define pwm0_count  (*(volatile uint32_t *) (pwm0_base + 0x08))
#define pwm0_scount (*(volatile uint32_t *) (pwm0_base + 0x10))
#define pwm0_cmp0   (*(volatile uint32_t *) (pwm0_base + 0x20))
#define pwm0_cmp1   (*(volatile uint32_t *) (pwm0_base + 0x24))
#define pwm0_cmp2   (*(volatile uint32_t *) (pwm0_base + 0x28))
#define pwm0_cmp3   (*(volatile uint32_t *) (pwm0_base + 0x2C))

#define pwm1_cfg    (*(volatile uint32_t *) (pwm1_base + 0x00))
#define pwm1_count  (*(volatile uint32_t *) (pwm1_base + 0x08))
#define pwm1_scount (*(volatile uint32_t *) (pwm1_base + 0x10))
#define pwm1_cmp0   (*(volatile uint32_t *) (pwm1_base + 0x20))
#define pwm1_cmp1   (*(volatile uint32_t *) (pwm1_base + 0x24))
#define pwm1_cmp2   (*(volatile uint32_t *) (pwm1_base + 0x28))
#define pwm1_cmp3   (*(volatile uint32_t *) (pwm1_base + 0x2C))

#define pwm2_cfg    (*(volatile uint32_t *) (pwm2_base + 0x00))
#define pwm2_count  (*(volatile uint32_t *) (pwm2_base + 0x08))
#define pwm2_scount (*(volatile uint32_t *) (pwm2_base + 0x10))
#define pwm2_cmp0   (*(volatile uint32_t *) (pwm2_base + 0x20))
#define pwm2_cmp1   (*(volatile uint32_t *) (pwm2_base + 0x24))
#define pwm2_cmp2   (*(volatile uint32_t *) (pwm2_base + 0x28))
#define pwm2_cmp3   (*(volatile uint32_t *) (pwm2_base + 0x2C))

#define PWM_CFG_CMP3IP    0x80000000  // [31]
#define PWM_CFG_CMP2IP    0x40000000  // [30]
#define PWM_CFG_CMP1IP    0x20000000  // [29]
#define PWM_CFG_CMP0IP    0x10000000  // [28]
#define PWM_CFG_CMP3GANG  0x08000000  // [27]
#define PWM_CFG_CMP2GANG  0x04000000  // [26]
#define PWM_CFG_CMP1GANG  0x02000000  // [25]
#define PWM_CFG_CMP0GANG  0x01000000  // [24]

#define PWM_CFG_CMP3CTR   0x00080000  // [19]
#define PWM_CFG_CMP2CTR   0x00040000  // [18]
#define PWM_CFG_CMP1CTR   0x00020000  // [17]
#define PWM_CFG_CMP0CTR   0x00010000  // [16]

#define PWM_CFG_ENONESHOT 0x00002000  // [13]
#define PWM_CFG_ENALWAYS  0x00001000  // [12]

#define PWM_CFG_DEGLITCH  0x00000400  // [10]
#define PWM_CFG_ZEROCMP   0x00000200  // [9]
#define PWM_CFG_STICKY    0x00000100  // [8]
#define PWM_CFG_SCALE     0x0000000F  // [3:0]

//
// PRCI block
//

uint32_t clock_init_ext_dir (void);  // lives in prci.s
uint32_t clock_init_int_dir (void);  // lives in prci.s
uint32_t clock_init_int (uint32_t hfclk_hz);  // lives in prci.s
uint32_t clock_init_ext (uint32_t hfclk_hz);  // lives in prci.s

void clock_hfrosc_ena (void);  // lives in prci.s
void clock_hfrosc_dis (void);  // lives in prci.s
uint32_t clock_hfrosc_adj (uint32_t lfrdiv, uint32_t lfrtrim);  // lives in prci.s
uint32_t clock_lfrosc_adj (uint32_t lfrdiv, uint32_t lfrtrim);  // lives in prci.s
void clock_wait_mtime (void);  // lives in prci.s
void clock_freq_mtime (void);  // lives in prci.s
void clock_freq_rtc (void);  // lives in prci.s
void clock_freq_wdt (void);  // lives in prci.s
uint32_t clock_meas (uint32_t m);  // lives in prci.s

//// state machine transitions
// INIT state
void clock_init_init (void);  // lives in prci.s
void clock_init_xdir (void);  // lives in prci.s
void clock_init_rdir (uint32_t hfrtrim, uint32_t hfrdiv);  // lives in prci.s
void clock_init_xpll (uint32_t pllr, uint32_t pllf, uint32_t pllq, int32_t plld);  // lives in prci.s
void clock_init_rpll (uint32_t hfrtrim, uint32_t hfrdiv, uint32_t pllr, uint32_t pllf, uint32_t pllq, int32_t plld);  // lives in prci.s
// HFX_DIR state
void clock_xdir_xdir (void);  // lives in prci.s
void clock_xdir_rdir (uint32_t hfrtrim, uint32_t hfrdiv);  // lives in prci.s
void clock_xdir_xpll (uint32_t pllr, uint32_t pllf, uint32_t pllq, int32_t plld);  // lives in prci.s
void clock_xdir_rpll (uint32_t hfrtrim, uint32_t hfrdiv, uint32_t pllr, uint32_t pllf, uint32_t pllq, int32_t plld);  // lives in prci.s
void clock_xdir_init (void);  // lives in prci.s
// HFR_DIR state
void clock_rdir_rdir (uint32_t hfrtrim, uint32_t hfrdiv);  // lives in prci.s
void clock_rdir_xdir (void);  // lives in prci.s
void clock_rdir_xpll (uint32_t pllr, uint32_t pllf, uint32_t pllq, int32_t plld);  // lives in prci.s
void clock_rdir_rpll (uint32_t hfrtrim, uint32_t hfrdiv, uint32_t pllr, uint32_t pllf, uint32_t pllq, int32_t plld);  // lives in prci.s
void clock_rdir_init (void);  // lives in prci.s
// HFX_PLL state
void clock_xpll_xpll (uint32_t pllr, uint32_t pllf, uint32_t pllq, int32_t plld);  // lives in prci.s
void clock_xpll_xdir (void);  // lives in prci.s
void clock_xpll_rpll (uint32_t hfrtrim, uint32_t hfrdiv, uint32_t pllr, uint32_t pllf, uint32_t pllq, int32_t plld);  // lives in prci.s
void clock_xpll_rdir (uint32_t hfrtrim, uint32_t hfrdiv);  // lives in prci.s
void clock_xpll_init (void);  // lives in prci.s
// HFR_PLL state
void clock_rpll_rpll (uint32_t hfrtrim, uint32_t hfrdiv, uint32_t pllr, uint32_t pllf, uint32_t pllq, int32_t plld);  // lives in prci.s
void clock_rpll_xdir (void);  // lives in prci.s
void clock_rpll_rdir (uint32_t hfrtrim, uint32_t hfrdiv);  // lives in prci.s
void clock_rpll_xpll (uint32_t pllr, uint32_t pllf, uint32_t pllq, int32_t plld);  // lives in prci.s
void clock_rpll_init (void);  // lives in prci.s

void dly (uint32_t n) {  // n=1000
  volatile uint32_t x;
  x = 0;
  while( x < n ) x++;
}

void dlylong (uint32_t n, uint32_t m) {  // n=1000,3000,10000; m=5000
  volatile uint32_t x, xx;
  x = 0;
  while( x < n )
  {
    x++;
    xx = 0;
    while( xx < m ) xx++;
  }
}
 
void main (void)
{
  uint32_t hfclk_hz;

  volatile uint32_t y;

  //
  // initialize timers
  //

  aon_rtccfg &= ~(AON_RTCCFG_ENALWAYS | 0xf);
  aon_rtccountlo = 0;
  aon_rtccounthi = 0;
  aon_rtcs = 0;
  aon_rtccmp0 = 0;
  aon_rtccfg = (AON_RTCCFG_ENALWAYS | 0);  // scale 0..15

  aon_wdogkey = AON_WDOGCFG_KEY;
  aon_wdogcfg &= ~(AON_WDOGCFG_ENALWAYS | AON_WDOGCFG_ZEROCMP | 0xf);
  aon_wdogkey = AON_WDOGCFG_KEY;
  aon_wdogcount = 0;
  aon_wdogkey = AON_WDOGCFG_KEY;
  aon_wdogs = 0;
  aon_wdogkey = AON_WDOGCFG_KEY;
  aon_wdogcmp0 = 0;
  aon_wdogkey = AON_WDOGCFG_KEY;
  aon_wdogcfg |= (AON_WDOGCFG_ENALWAYS | 0);  // scale 0..15

  //
  // external monitor signal for internal clock ... divided by 1000x
  //

  pwm1_cfg =0;//DOESNT WORK! &= ~(PWM_CFG_ENALWAYS | PWM_CFG_DEGLITCH | PWM_CFG_ZEROCMP | 0xf);  // scale 0..15
  pwm1_count = 0;
  pwm1_scount = 0;
  pwm1_cmp0 = (1000) - 1;
  pwm1_cmp1 = (pwm1_cmp0 + 1) >> 1;
  pwm1_cfg |= (PWM_CFG_ENALWAYS | PWM_CFG_DEGLITCH | PWM_CFG_ZEROCMP | 0);  // scale 0..15
  gpio_iof_sel   |=  (1UL << GPIO19_PWM1_1);  // special function i/o #1
  gpio_iof_en    |=  (1UL << GPIO19_PWM1_1);  // special function i/o mode

  //
  // marker (external monitor signal) for transition context switch
  //

  gpio_iof_en    &= ~(1UL << GPIO21_PWM1_2);  // general (direct) function i/o mode
  gpio_output_en |=  (1UL << GPIO21_PWM1_2);
  gpio_input_en  |=  (1UL << GPIO21_PWM1_2);
  gpio_pue       &= ~(1UL << GPIO21_PWM1_2);
  gpio_rise_ie   |=  (1UL << GPIO21_PWM1_2);
  gpio_fall_ie   &= ~(1UL << GPIO21_PWM1_2);
  gpio_high_ie   &= ~(1UL << GPIO21_PWM1_2);
  gpio_low_ie    &= ~(1UL << GPIO21_PWM1_2);

  gpio_output_val &= ~(1UL << GPIO21_PWM1_2);  // low

  //
  // state machine transition test
  //

  clock_init_xdir();

  while (1)
  {
    gpio_output_val ^= (1UL << GPIO21_PWM1_2);  // toggle
    clock_xdir_rdir(5, 8);  // hfrdiv, hfrtrim
    dly(1000);

    gpio_output_val ^= (1UL << GPIO21_PWM1_2);  // toggle
    clock_rdir_xpll(1, 31, 3, -1);  // pllr, pllf, pllq, plld
    dly(1000);

    gpio_output_val ^= (1UL << GPIO21_PWM1_2);  // toggle
    clock_xpll_rpll(5, 8, 1, 31, 3, -1);  // hfrdiv, hfrtrim, pllr, pllf, pllq, plld
    dly(1000);

    gpio_output_val ^= (1UL << GPIO21_PWM1_2);  // toggle
    clock_rpll_xdir();
    dly(1000);
  }


  //
  // clock source switching test in direct (non-pll) mode
  //

  clock_init_xdir();

  while(1)
  {
    gpio_output_val ^= (1UL << GPIO21_PWM1_2);  // toggle
    clock_xdir_rdir(4, 13);  // hfrdiv, hfrtrim    4   13
    dly(1000);

    gpio_output_val ^= (1UL << GPIO21_PWM1_2);  // toggle
    clock_rdir_xdir();
    dly(1000);
  }


  //
  // clock source ring oscillator frequency measurement
  //
/*
  clock_init_xdir();
  //while(1);  // stop here for frequency measurement of HFX

  clock_xdir_rdir(5, 16);  // hfrdiv, hfrtrim
  //while(1);  // stop here for frequency measurement of HFR

  clock_lfrosc_adj(3, 16);  // lfrdiv, lfrtrim = 30 KHz
  while(1) clock_freq_mtime();  // stop here for frequency measurement of LFR

  //clock_xdir_rdir(0, 0);  // hfrdiv, hfrtrim
  //clock_lfrosc_adj(5, 10);  // lfrdiv, lfrtrim = 16 KHz
  //clock_lfrosc_adj(3, 19);  // lfrdiv, lfrtrim = 16 KHz
  //while(1) clock_freq_rtc();  // div16 from lfclk
  while(1) clock_freq_wdt();  // div16 from lfclk

//  clock_xdir_xpll(1, 31, 1, -1);  // pllr, pllf, pllq, plld
  //while(1) clock_wait_mtime();  // calibrate waitmtime_loop (mtime0=0)//

  while(1)
  {
    for (y=16; y<32; y++)  // trim loop
    {
      //
      // HFR measurement, with hardware direct (pwm) marker
      //
      clock_xdir_rdir(0, y);  // hfrdiv, hfrtrim
      if (y>16)
      {
        // long pause for faster clock rate
        dlylong(10000, 5000);
      }
      else
      {
        // short(er) pause for slower clock rate
        dlylong(1000, 5000);
      }

      //
      // LFR measurement, with software indirect (mtime) marker
      //
//      clock_lfrosc_adj(0, y);  // lfrdiv, lfrtrim
//      clock_freq_mtime();  // direct from lfclk
      //clock_freq_rtc();  // div16 from lfclk
      //clock_freq_wdt();  // div16 from lfclk
    }
  }
*/
  //
  // clock source switching test in pll mode
  //
/*
  clock_init_xdir();
  clock_xdir_rdir(0, 0);  // hfrdiv, hfrtrim
  //clock_rdir_xpll(1, 31, 3, 1);

  //while(1);  // stop here for frequency measurement

  while(1)
  {
    //gpio_output_val ^= (1UL << GPIO21_PWM1_2);  // toggle
    //clock_xpll_xpll(1, 31, 3, 1);  // pllr, pllf, pllq, plld

    //for (y=0; y<31; y++)  // trim loop
    {
      //clock_rdir_rdir(0, y);  // hfrdiv, hfrtrim
      //gpio_output_val ^= (1UL << GPIO21_PWM1_2);  // toggle
      hfclk_hz = clock_meas( 0 );  // 4=100us, 4000=1sec
    }
    //dly(1000);
  }
*/

  //
  // clock source switching test in direct (non-pll) mode
  //
/*
  clock_init_xdir();
  clock_xdir_rdir(5, 8);  // hfrdiv, hfrtrim

  while(1)
  {
    gpio_output_val ^= (1UL << GPIO21_PWM1_2);  // toggle
    clock_rdir_rdir(5, 8);  // hfrdiv, hfrtrim
    dly(1000);

    gpio_output_val ^= (1UL << GPIO21_PWM1_2);  // toggle
    clock_rdir_rdir(15, 16);  // hfrdiv, hfrtrim
    dly(1000);

    gpio_output_val ^= (1UL << GPIO21_PWM1_2);  // toggle
    clock_rdir_rdir(8, 8);  // hfrdiv, hfrtrim
    dly(1000);

    gpio_output_val ^= (1UL << GPIO21_PWM1_2);  // toggle
    clock_rdir_rdir(4, 13);  // hfrdiv, hfrtrim
    dly(1000);
  }
*/

  //
  // pll test with different clock sources
  //
/*
  clock_init_xdir();

  while(1)
  {
    for (y = 0; y < 0x30; y+=0x2f)
    {
      clock_hfrosc_adj( y, 16 );
      for (x = 0; x < 10; x++)
      {
        gpio_output_val ^= (1UL << GPIO21_PWM1_2);  // toggle
      }
    }
  }
*/

}
