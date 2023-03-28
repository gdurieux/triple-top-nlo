#!/usr/bin/python3

import numpy as np
import re, sys

def printout(dic):

    scales   = list(sorted(set(key[0] for key in dic)))
    allpdfs  = [key[2] for key in dic]
    pdfsets  = list(sorted(set(allpdfs)))
    pdfcount = [len([1 for item in allpdfs if item==pdf]) for pdf in pdfsets]
    mainpdf  = pdfsets[np.argmax(pdfcount)]
    
    # give scale variation along the muR=muF line
    shift    = 0.
    xsecs    = 1e3*np.array([dic[scale,scale,mainpdf] for scale in scales])
    var      = np.interp([shift-1,shift+1., shift],np.log2(scales),xsecs)

    pdfsets.pop(pdfsets.index(mainpdf))
    pdfvars  = 1e3*np.array([dic[1.,1.,pdf] for pdf in pdfsets])

    print('\t{:<5.2g} fb {:+.2g}% {:+.2g}% (scale) +-{:.2g}% (pdf)'.format(
        var[2], *list((var[:2]/var[2]-1)*100),
        np.abs(np.std(pdfvars-var[2])/var[2]*100) if len(pdfvars)>0 else np.nan
        ))

dics = []
for dat in sys.argv[1:]:
    print(dat)
    with open(dat) as f:
        dat = f.read()
    val = [list(map(float,re.findall('[0-9+-e]+',line))) for line in dat.split('\n') if len(line)>1 and line[0]!="#"]
    dic = {(line[0],line[1],line[4]):line[5] for line in val}
    printout(dic)
    dics.append(dic)


sumdic = {}
for key in dics[0]:
    sumdic[key] = np.sum( dic[key] for dic in dics )
print('sum:')
printout(sumdic)

