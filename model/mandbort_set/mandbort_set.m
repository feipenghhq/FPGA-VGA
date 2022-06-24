# ---------------------------------------------------------------
# Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
#
# Author: Heqing Huang
# Date Created: 06/22/2022
# ---------------------------------------------------------------
#
# Mandbort Set model.
# Taken from ECE5760
# https://people.ece.cornell.edu/land/courses/ece5760/LABS/s2016/mandelbrot.m
#
# ---------------------------------------------------------------

termination = 100;
x = linspace(-2,1,640);
y = linspace(-1,1,480);
x_index = 1:length(x) ;
y_index = 1:length(y) ;
img = zeros(length(y),length(x));


for k=x_index
    for j=y_index
        z = 0;
        n = 0;
        c = x(k)+ y(j)*i ;%complex number
        while (abs(z)<2 && n<termination)
            z = z^2 + c;
            n = n + 1;
        end
        img(j,k) = n;
    end
end

imagesc(img)
colormap(summer)
pause (5);
in = input('Input required:', 's');
