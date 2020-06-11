
from astropy.io import fits
import numpy as np
import sys
import json

filename = sys.argv[1]

data = fits.getdata(filename)
colavg = []
for ind, col in enumerate(np.transpose(data)):
    colavg.append([ind, int(np.sum(col))/len(col)])

result = {
    #"color": "red",
    "label": "column avg vs. column",
    "data": colavg,
}
print(json.dumps(result))
sys.exit(100)
