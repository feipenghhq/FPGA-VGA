# ---------------------------------------------------------------
# Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
#
# Author: Heqing Huang
# Date Created: 05/02/2022
# ---------------------------------------------------------------
# Video Daisy System testbench
# ---------------------------------------------------------------


import cocotb
from cocotb import top
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

async def clock_gen(clock, period=10):
    """ Generate Clock """
    c = Clock(clock, period, units="ns")
    await cocotb.start(c.start())

async def reset_gen(reset, clock, time=100):
    """ Reset the design """
    reset.value = 1
    await Timer(time, units="ns")
    await RisingEdge(clock)
    reset.value = 0
    await RisingEdge(clock)
    cocotb.top.log.info(f"Reset {reset} Done!")

async def setup_clk_domain(clock, reset, period=10):
    await clock_gen(clock, period=period)
    await reset_gen(reset, clock)
    await RisingEdge(clock)

async def setup(dut):
    await cocotb.start(setup_clk_domain(dut.pixel_clk, dut.pixel_rst, 40))
    await cocotb.start(setup_clk_domain(dut.sys_clk, dut.sys_rst, 10))

@cocotb.test()
async def sanity(dut):
    await setup(dut)
    dut.ca_rule.value = 4
    await Timer(5000, units="us")