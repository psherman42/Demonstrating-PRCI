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

And so forth,

    clock_rdir_xpll(1, 31, 3, -1);  // pllr, pllf, pllq, plld
    clock_xpll_rpll(5, 8, 1, 31, 3, -1);  // hfrdiv, hfrtrim, pllr, pllf, pllq, plld
    clock_rpll_xdir();
    ...

In general eleven steps must be carefully followed when making transition from one clock path mode to another.
![FE310 PRCI Programming Sequence](https://user-images.githubusercontent.com/36460742/221101136-a13dee28-f667-4593-a86e-5df5be89b06a.PNG)

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
