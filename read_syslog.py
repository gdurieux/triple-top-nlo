#!/usr/bin/python3

# e.g.:
# ./read_syslog.py tttjm-3mt.pdf ./gen_tttjm_cs8/Events/run_13/parton_systematics.log ./gen_tttjm_cs8/Events/run_14_LO/parton_systematics.log ./gen_tttjm_4fs_lo/Events/run_08/parton_systematics.log

# ./read_syslog.py tttwm-ht2.pdf ./gen_tttwm/Events/run_08/parton_systematics.log  ./gen_tttwm/Events/run_09_LO/parton_systematics.log ./gen_tttwm_4fs_lo/Events/run_09/parton_systematics.log

import numpy as np
import matplotlib.pyplot as plt
import re, sys


cols = [ i['color'] for i in plt.rcParams['axes.prop_cycle'] ]
plt.rcParams.update({'font.size': 15})
plt.rc('font', family='serif')
plt.rc('text', usetex=True)

#def savefig(fname,**kwargs):
#    plt.savefig(fname,**kwargs)
#    get_ipython().system('~/.local/share/nautilus/scripts/untrim.sh %s'%fname)
#    get_ipython().system('gs -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -dEmbedAllFonts=true -sOutputFile=%s -f %s'%(fname.replace('pdf','tmp'),fname))
#    get_ipython().system('mv %s %s'%(fname.replace('pdf','tmp'),fname))

def show(Z,shift=0,show=True,subs=True,fs=''):
    if subs:
        plt.subplots(1,3,figsize=(15,5))
    for i,(x,y,z) in enumerate(Z[::-1]):
        ix = np.argmin(np.abs(np.array(x)-2**shift)) #int(len(x)/2)# 
        iy = np.argmin(np.abs(np.array(y)-2**shift)) #int(len(y)/2)# 
        plt.subplot(1,3,i+1)
        plt.title(['LO','NLO'][i])
        plt.contour(np.log(x)/np.log(2),np.log(y)/np.log(2),z/z[ix,iy],
                    levels=[.6,.8, 1, 1.2,1.4], vmin=-.2, vmax=1.4) #, vmin=.8, vmax=1.2)
#                     levels=[.5,.6,.7,.8,.9,1,1.1,1.2,1.3,1.4,1.5]) #, vmin=.8, vmax=1.2)
        plt.plot(np.log(x[ix])/np.log(2),np.log(y[iy])/np.log(2),'k+')
        plt.xlabel('$\\log_2\\frac{\\mu_{R}}{\\mu_0}$')
        plt.ylabel('$\\log_2\\frac{\\mu_{F}}{\\mu_0}$', va='center')
        plt.xticks(np.array([-3,-2,-1,0,1,2,3])+int(shift))
        plt.tick_params(right=True, top=True, which='both',labelright=False)
        plt.xlim(-3+shift,3+shift)
        plt.ylim(-3+shift,3+shift)
        
    plt.subplot(1,3,3)
    for i,(x,y,z) in enumerate(Z[::-1]):
        if x!=y:
            raise()
        v = list(np.log(x)/np.log(2))
        w = 1e3*np.array([z[i,i] for i in range(len(z[0]))])
        plt.plot(v,w,label=['LO'+fs,'NLO'][i])
        var = np.interp([-1+shift,+1.+shift, shift],v,w)
        print('{:<5.3g} fb {:+.2g}% {:+.2g}% ({:.2g}-{:.2g})'.format(
            var[2], *list((var[:2]/var[2]-1)*100), *list(sorted(var[:2]))))
        plt.plot(shift,var[2],'k+')
    plt.xlim(-3+shift,3+shift)
    plt.ylim(0,1.)
    plt.legend()
    plt.xlabel('$\\log_2\\frac{\\mu_{R}=\\mu_{F}}{\\mu_0}$')
    plt.ylabel('$\\sigma({\\rm 13 TeV)\;  [fb]}$', va='bottom')
    plt.xticks(np.array([-3,-2,-1,0,1,2,3])+int(shift))
    plt.tick_params(right=True, top=True, which='both',labelright=False)

    if show:
        plt.show()

def read_syslog(dat):
    val = [list(map(float,re.findall('[0-9+-e]+',line))) for line in dat.split('\n') if len(line)>1 and line[0]!="#"]
    dic = {(line[0],line[1]):line[5] for line in val}
    x = sorted(list(set(np.array(val)[:,0])))
    y = sorted(list(set(np.array(val)[:,1])))
    w = [[dic[xx,yy] for yy in y] for xx in x]
    return([[x,y,np.array(w)]])

out = sys.argv[1]

# NLO and LO
Z   = []
for dat in sys.argv[2:4]:
    with open(dat) as f:
        Z += read_syslog(f.read())
show(Z,show=False)
    
# LO 4FS if present
if len(sys.argv)==5:
    with open(sys.argv[4]) as f:
        Z = read_syslog(f.read())
    show(Z,show=False,subs=False,fs=' 4FS')
    
plt.savefig(out)
plt.show()
