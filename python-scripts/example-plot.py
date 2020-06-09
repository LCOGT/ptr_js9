import sys, json, random

data_to_plot = []

for column in range(20):
    value = random.randint(0,5)
    data_to_plot.append([column,value])

properly_formatted_output = json.dumps({
    "color": "red",
    "label": "random.randint(0,10) vs. column",
    "data": data_to_plot,
})

print(properly_formatted_output)
sys.exit(100)
