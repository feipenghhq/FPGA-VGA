# FPGA VGA

This repo contains some VGA/Video related IPs designed for FPGA

## VGA System IP

- vga_core: This is a simple vga controller with an internal line buffer and frame synchronization logic

## Video core IP

- bar_core: This IP generate generate some bar pattern on the screen
- dummy_core: This is a dummy core which feed the pixel input to its output
- rgb2gray_core: This IP convert the RGB color to gray scale
- sprite_core: This IP display a sprite in a given location in the frame.


## Video System and its demo FPGA projects

### video_daisy_system

- This design contains the bar_core, sprite_core, rgb2gray_core, and the vga_core.
- The corresponding FPGA projects is `FPGA-VGA/fpga/proj/video_daisy_system`. The target FPGA board is DE2 FPGA board.
- To run the demo: `cd FPGA-VGA/fpga/proj/video_daisy_system` and then do `make pgm`

## References

- [FPGA Prototyping by VHDL Examples](https://www.amazon.com/FPGA-Prototyping-VHDL-Examples-Spartan-3/dp/0470185317) by Pong P. Chu