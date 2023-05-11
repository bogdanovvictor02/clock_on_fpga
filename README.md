# Simple clock on FPGA
This is a simple FPGA clock. They support 4-bit time output to a multiplexed display and full time setting.
## Architecture
![clock_architecture]([[https://github.com/PathCreator/clock_of_fpga/blob/main/clock.png](https://github.com/bogdanovvictor02/clock_on_fpga/blob/main/clock.png)](https://github.com/bogdanovvictor02/clock_on_fpga/blob/main/clock.png?raw=true))
## Module interface
```verilog
clock_top
(
    input           i_Clock,
    input           i_Button_Set,
    input           i_Button_Up,

    output  [7:0]   o_Segments,
    output  [3:0]   o_Digits
);
```
__Default connections:__
* Input clock: External Quartz 32768Hz or internal PLL
* Input button: Logic zero - gnd, unit - vcc. That is, an inverter is needed for the pull-up button
* Output display: common cathode indicators. Inverters are needed for the common anode
## Settings time
Two buttons are used to set the time.
* The __SET__ button is required to switch 3 modes: __IDLE__, __SET MIN__, __SET HOUR__. When entering the setting mode, the seconds are reset.
* The __UP__ button is needed to increase the clock. When the maximum value is reached, a reset (looped).
