import filecmp
#compares to bmps
is_same = filecmp.cmp('burning_ship_fractal_s.bmp', 'burning_ship_fractal_c.bmp')
print(f"{is_same}")