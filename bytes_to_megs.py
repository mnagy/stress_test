#!/usr/bin/python3

import csv
import sys

def to_mb(i):
    return str(round(int(i)/1024/1024, 3))

for row in csv.reader(sys.stdin):
    row = [x if int(x) < 1024 else to_mb(x) for x in row]
    print(",".join(row))
