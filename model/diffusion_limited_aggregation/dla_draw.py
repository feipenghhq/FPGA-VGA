#!/usr/bin/python3

# ---------------------------------------------------------------
# Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
#
# Author: Heqing Huang
# Date Created: 05/024/2022
# ---------------------------------------------------------------
#
# Draw the DLA image based on the output CSV
#
# ---------------------------------------------------------------



import sys
from PIL import Image, ImageDraw

# some globals parameters

# Target picture size

def read_dla_csv(file):
    """ Read the dla csv file """
    fptr = open(file, 'r')
    size = tuple(map(int, fptr.readline().split(',')))
    contents = fptr.readlines()
    pixels = []
    for xy in contents:
        xy = xy.rstrip()
        xy = tuple(map(int, xy.split(',')))
        pixels.append((xy, (255, 255, 0)))
    return size, pixels

def draw_image(file, size, pixels):
    """ Extract the rgb color from image """
    img = Image.new('RGB', size)
    for pos, rgb in pixels:
        img.putpixel(pos, rgb)
    img.save(file)

def run():
    size, pixels = read_dla_csv("dla_model.csv")
    draw_image("dla_model.png", size, pixels)


if __name__ == "__main__":
    run()