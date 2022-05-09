#!/usr/bin/python3

# ---------------------------------------------------------------
# Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
#
# Author: Heqing Huang
# Date Created: 05/07/2022
# ---------------------------------------------------------------
# Python program to extract rgb color from a image and create mem
# files for the sprite core
# ---------------------------------------------------------------

#
# Usage:
# ./sprite4.py <image> <output_name>
#

import sys
from PIL import Image, ImageDraw

image = sys.argv[1]
outfile = sys.argv[2]

# some globals parameters

# Target sprite size
X_SIZE = 32
Y_SIZE = 32

# RGB size
R_SIZE = 4
G_SIZE = 4
B_SIZE = 4

def extract_rgb(file, x_size=32, y_size=32):
    """ Extract the rgb color from image """
    img = Image.open(file, 'r')
    width, height = img.size
    print(f"Original image size = {width} x {height}")
    img = img.resize((x_size, y_size))
    img = img.convert('RGB')
    array = []
    for y in range(y_size):
        for x in range(x_size):
            rgb = img.getpixel((x,y))
            array.append(rgb)
    return array

def extract_color(color, size=8):
    """
        Extract color based on size
        Assuming the original color size is 8 bits
    """
    if size >= 8:
        return color
    else:
        mask = (1 << size) - 1
        shift = 8 - size
        return (color >> shift) & mask

def create_mem(rgb_array, outfile, r_size, g_size, b_size):
    """ Create mem file for the sprite ram """
    FILE = open(outfile, 'w')
    for rgb in rgb_array:
        r, g, b = rgb
        r1 = extract_color(r, r_size)
        g1 = extract_color(g, g_size)
        b1 = extract_color(b, b_size)
        color = b1 | (g1 << b_size) | (r1 << (g_size + b_size))
        FILE.write(hex(color)[2:] + "\n")
    FILE.close()


def run(image):
    color_array = extract_rgb(image, X_SIZE, Y_SIZE)
    create_mem(color_array, outfile, R_SIZE, G_SIZE, B_SIZE)

if __name__ == "__main__":
    run(image)