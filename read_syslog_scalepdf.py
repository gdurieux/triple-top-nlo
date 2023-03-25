#!/usr/bin/python3

import numpy as np
import matplotlib.pyplot as plt
import re, sys

def printit(Z):
    for i,(x,y,z,p) in enumerate(Z[::-1]):
        if x!=y:
            raise()
        v = list(np.log(x)/np.log(2))
        w = 1e3*np.array([z[i,i] for i in range(len(z[0]))])
        var = np.interp([-1,+1., 0.0],v,w)
        p *= 1e3
        print('\t{:<5.2g} fb {:+.2g}% {:+.2g}% (scale) +-{:.2g}% (pdf)'.format(
            var[2], *list((var[:2]/var[2]-1)*100),
            np.abs(np.std(p-var[2])/var[2]*100)
            ))

def read_syslog(dat,pdf=244600):
    val = [list(map(float,re.findall('[0-9+-e]+',line))) for line in dat.split('\n') if len(line)>1 and line[0]!="#"]
    dic = {(line[0],line[1]):line[5] for line in val if line[4]==pdf}
    x = sorted(list(set(np.array(val)[:,0])))
    y = sorted(list(set(np.array(val)[:,1])))
    w = [[dic[xx,yy] for yy in y] for xx in x]
    pdfs = [line[5] for line in val if line[0]==1 and line[1]==1]
    return([[x,y,np.array(w),np.array(pdfs)]])


Z   = []
for dat in sys.argv[1:]:
    print(dat)
    with open(dat) as f:
        Z = read_syslog(f.read())
    printit(Z)
