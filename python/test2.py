
from astropy.io import fits
import numpy as np
import sys

filename = sys.argv[1]

hdu_list = fits.open(filename)
print(hdu_list.info())
#print(filename)
