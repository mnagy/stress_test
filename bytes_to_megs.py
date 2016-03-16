#!/usr/bin/python3

import matplotlib.pyplot as plt
# import csv
import sys
import fileinput


def to_mb(i):
    return str(round(int(i)/1024/1024, 3))

cols = []
title = 'No title'
fig_name = sys.argv[1] if len(sys.argv) > 1 else 'fig.png'
label = 'Initial'
x = []
y = []
data = {}
# for row in csv.reader(sys.stdin):
for line in fileinput.input():
    data.setdefault(fileinput.filename(), {
        'label': 'No label',
        'x': [],
        'y': []
    })
    d = data[fileinput.filename()]
    if fileinput.isfirstline():
        d['label'] = line.strip("# ")
        params = map(lambda x: x.strip(), d['label'].split(','))
        for p in params:
            k, v = p.split('=')
            d[k] = v
    else:
        row = line.split(',')
        d['x'].append(int(row[0]))
        d['y'].append(int(row[-1])/1024/1024)
        # row = [x if int(x) < 1024 else to_mb(x) for x in row]
        # cols.append(row)
        # print(",".join(row))

workers = {
    '1': 'r',
    '2': 'g',
    '3': 'b',
    '4': 'c',
    '5': 'm',
    '6': 'b',
    '7': 'r',
    '8': 'g'
}
sleep = {
    '0': 'v',
    '0.1': '',
    '0.5': 'o',
    '1': '^'
}
exp = {
    '1': ':',
    '10': '--',
    '16': '-'
}

for d in data.values():
    if d['exp'] == '16':
        continue
    f = "{0}{1}{2}".format(workers[d['workers']], sleep[d['sleep']],
                           exp[d['exp']])
    plt.plot(d['x'], d['y'], f, label=d['label'])

for i in workers.keys():
    x = range(2, 33, 2)
    y = [50 + 15*int(i) + 0.1*a*int(i) for a in x]
    plt.plot(x, y, '{0}-'.format(workers[i]))

plt.title(title)
# plt.legend()
plt.show()
# plt.savefig("/tmp/graph.png")
