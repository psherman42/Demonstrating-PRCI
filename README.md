# Demonstrating-PRCI
Simple example showing how to control an SoC clock path

Described in more detail in the SiFive forum discussions as [Understanding the PRCI clock path](https://forums.sifive.com/t/understanding-the-prci-clock-path/5827).

Implments the following state machine to make clock path transitioning efficient and fool-proof.
![FE310 PRCI FSM](https://user-images.githubusercontent.com/36460742/221101107-0870d344-afb8-452b-a63b-e6f8a3fa6335.PNG)

State machine primitives are in source file [prci.s](https://github.com/psherman42/Demonstrating-PRCI/blob/main/prci.s)

It is a simple matter to get into any clock path. First, initialize the state machine, which always starts in the external direct path (assuming there is an external oscillator or other source connected):

    clock_init_xdir();

Tben invoke primitive functions as desired. For example, from the HFX DIR path th the HFR DIR path,

    clock_xdir_rdir(5, 8);  // hfrdiv, hfrtrim

And so forth, into the HFX PLL, HFR PLL, and back to the HFX DIR paths, respectively,

    clock_rdir_xpll(1, 31, 3, -1);  // pllr, pllf, pllq, plld
    clock_xpll_rpll(5, 8, 1, 31, 3, -1);  // hfrdiv, hfrtrim, pllr, pllf, pllq, plld
    clock_rpll_xdir();
    ...

Frequency in Hz of a ring oscillator composed of *b* inverter gates each *a* delay units long is given by the following equation.

$\Large Hz=\frac{1}{a \cdot (1 - \frac{(trim - 16)}{b}))}$

Where *trim* is the five-bit value from 0 to 31 (expressed as signed 2's complement from -16 to +15), and design paramters of two ring oscillators in the FE310 SoC have been determined empirically as:

**HFR**: a=11.558, b=35  (PRCI block base 0x1000 8000)  
**LFR**: a=8.728, b=31  (AON block base 0x1000 0000)  

Note that the *actual* power-up default frequency of **HFR**, with trim=0 (code=16) and div=4, is **17.3 MHz**; unlike 13.8 MHz which is stated in the FE310 Manual. Actually, trim=0 with **div=5** comes closer, with 14.4 MHz. All measurement data cnd calculations are in the [prci-clock.xlsx](https://github.com/psherman42/Demonstrating-PRCI/blob/main/prci-clock.xlsx) file.

Similarly, the *actual* power-up default frequency of **LFR**, with trim=0 (code=16) and div=4, is **22.9 KHz**; unlike 32 KHz which is stated in the FE310 Manual. Actually, trim=0 with **div=3** comes closer, with 28.6 KHz.

In general eleven steps must be carefully followed when making transition from one clock path mode to another.
![FE310 PRCI Programming Sequence](https://user-images.githubusercontent.com/36460742/221101136-a13dee28-f667-4593-a86e-5df5be89b06a.PNG)

The block diagram shown above matches the actual, physical hardware of the FE310 SoC yet is slightly different to what is shown in the FE310 Manual.

ERRATA: The PLL's last stage divisor, term *d*, is not where shown but actually between the *pllbypass* and *pllsel* switches, at position 10 shown above. Diagrams will be revised soon. PS

#### HFX DIR

The clock path derived from external crystal (or other) source, progressing directly through to the SoC, looks like this. Depending on transition to the next clock path state, some of the eleven steps are redundant and have been removed for speed, code size, and brevity.
![FE310 PRCI HFX Direct Clock Path](https://user-images.githubusercontent.com/36460742/221101141-ce8f8707-8bb6-4726-ab56-0a993a699b3c.PNG)

#### HFR DIR

The clock path derived from internal ring oscillator, progressing directly through to the SoC, looks like this:
![FE310 PRCI HFR Direct Clock Path](https://user-images.githubusercontent.com/36460742/221101143-d752a855-afc0-453f-bac8-a63edf52cc9e.PNG)

#### HFX PLL

The clock path derived from external crystal (or other) source, followed by adjustment of the PLL, looks like this:
![FE310 PRCI HFX PLL Clock Path](https://user-images.githubusercontent.com/36460742/221101145-8d91b8e3-5630-40f8-8b6d-534a13505def.PNG)

#### HFR PLL

The clock path derived from internal ring oscillator, followed by adjustment of the PLL, looks like this:
![FE310 PRCI HFR PLL Clock Path](https://user-images.githubusercontent.com/36460742/221101148-bde14001-33fb-44e0-bcd6-d3a8be0ff937.PNG)
