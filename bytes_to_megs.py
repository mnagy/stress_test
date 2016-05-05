#!/usr/bin/python3

"""Generate plots from csv files.

Usage: plot [options] <file>...

-o FILE  Save plot to a file.
"""

import matplotlib.pyplot as plt
# import csv
from docopt import docopt
import sys
import fileinput


args = docopt(__doc__)


def to_mb(i):
    return str(round(int(i)/1024/1024, 3))

cols = []
title = 'No title'
fig_name = sys.argv[1] if len(sys.argv) > 1 else 'fig.png'
label = 'Initial'
data = {}
avg_x = []
avg_y = {}
# for row in csv.reader(sys.stdin):
for line in fileinput.input(args["<file>"]):
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
        x = int(row[0])
        y = int(row[-1])
        d['x'].append(x)
        d['y'].append(y/1024/1024)
        avg_x.append(x)
        avg_y.setdefault(x, [])
        avg_y[x].append(y)
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

# """
for d in data.values():
    # if d['exp'] == '16':
    #     continue
    # f = "{0}{1}{2}".format(workers[d['workers']], sleep[d['sleep']],
    #                        exp[d['exp']])
    f = "{0}{1}".format(sleep[d['sleep']], exp.get(d['exp'], '-'))
    plt.plot(d['x'], d['y'], f, label=d['label'])
# """

"""
avg = []
for x in avg_x:
    avg.append(sum(avg_y[x])/len(avg_y[x])/1024/1024)
plt.plot(avg_x, avg, ".-")
"""

x = range(1, 32)
y = [30 + 7*int(a) for a in x]
plt.plot(x, y, '-')

plt.title(title)
# plt.legend()

if args["-o"]:
    plt.savefig(args["-o"])
else:
    plt.show()
