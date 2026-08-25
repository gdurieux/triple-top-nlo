#!/bin/bash
#
#SBATCH --chdir=.
#SBATCH --time=5-00:00
#SBATCH --cpus-per-task=10
#SBATCH --mem-per-cpu=4096
#SBATCH --partition=cp3
#SBATCH --qos=cp3
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null


## timestamp run
if [[ "$1" == "" ]] ; then
	NOW=`date +'%F_%H-%M-%S'`
else
	NOW=$1
fi

## current directory
if [[ "$2" == "" ]] ; then
	HERE=`pwd`
else
	HERE=$2
fi


## above is for slurm (do "sbatch <this file>")
## below is for htcondor (do "./<this file>")
if [[ $HOSTNAME == *"lxplus"* ]]; then
echo "executable      = $0
arguments             = $NOW $HERE
output                = \$(ProcId).out
error                 = \$(ProcId).err
log                   = ./\$(ClusterId)/\$(ProcId).log
output_directory      = ./\$(ClusterId)/
MY.XRDCP_CREATE_DIR   = True
+MaxRuntime           = 864000
RequestCpus           = 10
RequestMemory         = 10GB
queue" > tmp.sub
condor_submit tmp.sub            # condor submission
exit
fi

# looping over all that
TOPMASS="172.5"
TINYPTCUT="1.d0"                 # possibly set to a positive value for extra radiation plots
TOPWIDTH="1.481"                 # 1.481 GeV obtained at LO with MT=172.5, MW=80.379, MZ=91.1876, Gf=1.16639e-5
WWIDTH="2.045"                   # 2.045 GeV obtained at LO with MT=172.5, MW=80.379, MZ=91.1876, Gf=1.16639e-5
BWCUTOFF=""
VETO=""
SCALEFAC=""
EBEAM=""
PROC=""
PROCLINE=""
NLO=""
ORDER=""
OUTDIR=""

# loop over no b-veto or b-veto
for VETO in "" ; do # "" "_veto" ; do

# loop over scales, 0.5 means "0.5 times the default HT/2" i.e. HT/4
for SCALEFAC in 0.5 ; do

# loop over beam energies in GeV
for EBEAM in 6500. 6800. 7000. ; do # 6500. 6800. 7000. ; do

# loop over processes
for PROC in wp wbqq jm jp ; do # jm jp wm wp wbqq ; do

# loop over orders
for NLO in LO NLO ; do # LO NLO ; do
for ORDER in 1 2 3 4 ; do # 1 2 3 4 ; do

# diagram removal scheme
# 12 = DRW, 1 = DR1, 2 = DR2
for ISTR in 12 ; do # 12 1 2 ; do

# only do veto for NLO
if [ "$NLO" = "LO" ] && [ "$VETO" != "" ] ; then
continue
fi

# only do LO1,2,3 and NLO1 for tttw
if [ "$PROC" = "wp" ] || [ "$PROC" = "wm" ] ; then
	if [ "$NLO" = "NLO" ] && [ "$ORDER" != "1" ] ; then
		continue
	fi
	if [ "$NLO" = "LO" ] && [ "$ORDER" = "4" ] ; then
		continue
	fi
fi
# only do LO2,3,4 and NLO2 for tttj
# (didn't renumber from 1 for the first contributing order)
if [ "$PROC" = "jp" ] || [ "$PROC" = "jm" ] ; then
	if [ "$NLO" = "NLO" ] && [ "$ORDER" != "2" ] ; then
		continue
	fi
	if [ "$NLO" = "LO" ] && [ "$ORDER" = "1" ] ; then
		continue
	fi
fi
# only do NLO1 for qq>tttwb (it is LOonly process but with NLO1 coupling order)
if [ "$PROC" = "wbqq" ] && ( [ "$NLO" != "NLO" ] || [ "$ORDER" != "1" ] ) ; then
	continue
fi

# expansion
if [ "$NLO" = "NLO" ] ; then
EXPANSION=QCD
fi
if [ "$NLO" = "LO" ] ; then
EXPANSION=LOonly
fi

# process line
if [ "$PROC" = "jm" ] ; then
PROCLINE="generate p p > t~ t t  j  QCD^2<=$(( 8 - 2*$ORDER )) QED^2<=$(( 0 + 2*$ORDER )) [${EXPANSION}]"
WIDTH=$WWIDTH
fi
if [ "$PROC" = "jp" ] ; then
PROCLINE="generate p p > t t~ t~ j  QCD^2<=$(( 8 - 2*$ORDER )) QED^2<=$(( 0 + 2*$ORDER )) [${EXPANSION}]"
WIDTH=$WWIDTH
fi
if [ "$PROC" = "wp" ] ; then
PROCLINE="generate p p > t t~ t~ w+ QCD^2<=$(( 8 - 2*$ORDER )) QED^2<=$(( 0 + 2*$ORDER )) [${EXPANSION}]"
WIDTH=$TOPWIDTH
fi
if [ "$PROC" = "wm" ] ; then
PROCLINE="generate p p > t~ t t  w- QCD^2<=$(( 8 - 2*$ORDER )) QED^2<=$(( 0 + 2*$ORDER )) [${EXPANSION}]"
WIDTH=$TOPWIDTH
fi
if [ "$PROC" = "wbqq" ] ; then
PROCLINE="define p = u c d s u~ c~ d~ s~
generate p p > t t~ t~ w+ b QCD^2<=$(( 10 - 2*$ORDER )) QED^2<=$(( 0 + 2*$ORDER )) [LOonly]"
WIDTH=$TOPWIDTH                              # not actually needed, selecting outside the window done by hand from m(wb) histogram
fi


# width of the on-shell window 
for WINDOW in 40 ; do # 10 20 40 80
BWCUTOFF=`echo "scale=7 ; $WINDOW / $WIDTH " | bc`

# output directory
OUTDIR=gen_ttt${PROC}_${NLO}${ORDER}

PRECISION=0.01                               # fixed-order precision
NBCORES=10                                   # cores used by MG, match batch request above!!!!
exec >> ${OUTDIR}.log  2>&1                  # channel stdout+stderr to log file

# need to specify python3.8 for CS8, while CS9 has python3.9 as default already
date && echo "--- On host $HOSTNAME"
V=""
OUT=""
TRANSFER=""

### cism cluster
if [[ "`hostname --long`" == *"cism.ucl.ac.be"* ]]; then
echo "--- On ingrid, submit job from manneback or mb- node to have proper Python version"
module load releases/2024a
module load SciPy-bundle
module load matplotlib

OUT="$HERE/job-$NOW"
mkdir $OUT
date && echo "--- Transfer directory: $OUT"

SCRATCH=/scratch/$USER/$SLURM_JOB_ID
mv ${OUTDIR}.log $SCRATCH/${OUTDIR}.log
cp $0 $SCRATCH/${OUTDIR}.sh
cd $SCRATCH
exec >> ${OUTDIR}.log  2>&1

V=3
fi


### lxplus cluster
if [[ "`hostname --long`" == *"cern.ch"* ]]; then
date && echo "--- Host: `hostname --long`"

OUT="$HERE/job-$NOW"
mkdir $OUT
date && echo "--- Transfer directory: $OUT"

V=3.9
fi


### echo parameters
echo "----"
echo "EBEAM: $EBEAM"
echo "PROC: $PROC"
echo "SCALEFAC: $SCALEFAC"
echo "PROCLINE: $PROCLINE"
echo "NLO: $NLO"
echo "ORDER: $ORDER"
echo "ISTR: $ISTR"
echo "BWCUTOFF: $BWCUTOFF"
echo "VETO: $VETO"
echo "OUTDIR: $OUTDIR"
echo "TINYPTCUT: $TINYPTCUT"




### data transfer command
#TRANSFER="rsync -av ${OUTDIR}.log ${OUTDIR} $OUT/ "               # full directory transfer
TRANSFER="rsync -av ${OUTDIR}.log *.sh *.HwU *.py ${OUTDIR}/Events/ $OUT/ "   # run_xx directories only
#TRANSFER=""                                                       # no data transfer


PYTHON=python${V}
F2PY=f2py${V}                                   # f2py needed for reweighting
echo "--- Python version `$PYTHON --version`"


#VERSION=351                                    # 2023-07-11
#MGLINK=https://github.com/mg5amcnlo/mg5amcnlo/archive/refs/tags/v3.5.1.tar.gz
#VERSION=354                                    # 2024-04-05
#MGLINK=https://github.com/mg5amcnlo/mg5amcnlo/archive/refs/tags/v3.5.4.tar.gz
VERSION=358                                     # 2025-03-18
MGLINK=https://github.com/mg5amcnlo/mg5amcnlo/archive/refs/tags/v3.5.8.tar.gz
#VERSION=362                                    # 2025-03-19
#MGLINK=https://github.com/mg5amcnlo/mg5amcnlo/archive/refs/tags/v3.6.2.tar.gz
#VERSION=370                                    # 2026-04-29
#MGLINK=https://github.com/mg5amcnlo/mg5amcnlo/archive/refs/tags/v3.7.0.tar.gz
INIT="#
set run_mode 2                                  # 1 is for cluster, 2 for multicore  
set nb_core $NBCORES                            # adjust to cpus-per-task
set f2py_compiler ${F2PY}
#set auto_convert_model True                    # convert model to python3 automatically, DEPRECATED?
set acknowledged_v3.1_syntax True --global      # needed for v3.1 and above, but not for v3.7
set automatic_html_opening False
save options"                                   # write all that in config file


### setup madgraph if the tar.gz file is not present, assumes it is setup already otherwise
MGTAR=mg5_v${VERSION}.tar.gz
if [[ ! -f "$MGTAR" ]] ; then

### get MG
date && echo "--- Get madgraph"
wget -O $MGTAR $MGLINK
tar xzf $MGTAR
MGBASE=`tar tzf $MGTAR | grep -m1 'madgraph/$' | sed 's/\/madgraph\///'`

### get MadSTR
cd $MGBASE/PLUGIN/
wget https://github.com/mg5amcnlo/MadSTR/archive/refs/heads/bwcutoff.tar.gz
tar xzf bwcutoff.tar.gz
mv MadSTR-bwcutoff/MadSTR .
rm -r MadSTR-bwcutoff
cd $OLDPWD

### executable in MadSTR mode
MG="$PYTHON $MGBASE/bin/mg5_aMC --mode=MadSTR "
date && echo "--- Using MG executable: $MG"


### get utilities
date && echo "--- Install utilities"
echo "install lhapdf6
install ninja
install collier
" > ${OUTDIR}.cmd
time $MG -f ${OUTDIR}.cmd

#### add missing PDF set in index (waiting for commit https://gitlab.com/hepcedar/lhapdf/-/commit/630217945b604c4bf3ff279edcb2d6454733aa70 from 2024-06-24 to appear in LHAPDF release installed by MG)
#date && echo "--- Add NNPDF40...qed in index"
#PDFSETSINDEX=`find $MGBASE -name pdfsets.index`
#echo "335900 NNPDF40_nlo_as_01180_qed 1" >> "$PDFSETSINDEX"
#date && echo "--- Grep that"
#grep 335900 $PDFSETSINDEX


### transfer
date && echo "--- Transfer"
$TRANSFER


### end of madgraph setup
fi


MGBASE=`tar tzf $MGTAR | grep -m1 'madgraph/$' | sed 's/\/madgraph\///'`
date && echo "--- MGBASE: $MGBASE"

MGCONFIG="$MGBASE/input/mg5_configuration.txt"
date && echo "--- MGCONFIG: $MGCONFIG"

### need to point to LHAPDF (required for systematics reweighting)
TRY1=`grep -o "[^ ]\+/lhapdf6[^/]\+" ${MGCONFIG}`
TRY2=`pwd`/`find ./HEPTools -type d -name "lhapdf6_py3"`
if [[ "$TRY1" != "" ]] ; then
	LHAPDF=$TRY1
elif [[ "$TRY2" != "" ]] ; then
	LHAPDF=$TRY2
else
	echo "--- LHAPDF not set !!!!!!!!!!!!!!!!"
fi
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$LHAPDF/lib/
date && echo "--- Using LD_LIBRARY_PATH: $LD_LIBRARY_PATH"


### MG executable in MadSTR mode and initialisation
MG="$PYTHON $MGBASE/bin/mg5_aMC --mode=MadSTR "
date && echo "--- Using MG executable: $MG"



### generate and output
if [[ ! -d "${OUTDIR}" ]] ; then

echo "$INIT
import model loop_qcd_qed_sm_Gmu        #  -no_widths  # set them to zero by hand
$PROCLINE
output ${OUTDIR}
y# just in case some installation or overwritting is needed
" > ${OUTDIR}.cmd

date && echo "--- Generate and output"
time $MG -f ${OUTDIR}.cmd




#### change OSThres to 1d-8 instead of 1d-13
#date && echo "--- Change OSThres to 1.0d-8"
#sed -i '/#OSThres/{N;s/\n.\+/\n1.0d-8/}' ${OUTDIR}/Cards/MadLoopParams.dat
#echo "--- Grep that"
#grep -A1 '#OSThres' ${OUTDIR}/Cards/MadLoopParams.dat
#
#### add mcmodel=medium fortran flag, could consider -Wl,--no-relax too
#### to handle relocation truncation/overflow
#date && echo "--- Add mcmodel=medium fortan flag"
##sed -i 's/^\(FFLAGS *=\.*\)/\1 -mcmodel=large -Wl,--no-relax /' ${OUTDIR}/Source/make_opts
#sed -i 's/^\(FFLAGS *=\.*\)/\1 -mcmodel=medium /' ${OUTDIR}/Source/make_opts
#echo "--- Grep that"
#grep '^FFLAGS *=' ${OUTDIR}/Source/make_opts


if [ "$PROC" = "wbqq" ] ; then
## hardcode finite width to counter MG setting it automatically to zero
date && echo "--- Hardcode the width"
sed -i "s/^          IF (\.NOT\. CALCULATEDBORN) THEN/          IF (.NOT. CALCULATEDBORN) THEN\n            MDL_WT = $TOPWIDTH/" ${OUTDIR}/SubProcesses/P*/born.f
date && echo "--- Grep that"
grep -A2 "^          IF (\.NOT\. CALCULATEDBORN) THEN" ${OUTDIR}/SubProcesses/P*/born.f
fi


date && echo "--- Transfer"
$TRANSFER


### end of output setup
fi
date && echo "--- Transfer"
$TRANSFER


### fixed order analysis setup
date && echo "--- Change fixed-order analysis setup"
sed -i -e '/^fo_lhe_weight_ratio =/d' -e 's/^FO_ANALYSIS_FORMAT =.\+/FO_ANALYSIS_FORMAT = Hwu/' ${OUTDIR}/Cards/FO_analyse_card.dat
echo "--- Grep that"
grep -A1 '^FO_ANALYSIS_FORMAT =' ${OUTDIR}/Cards/FO_analyse_card.dat

### patch fixed order analysis to extract all orders
date
echo "--- Patching fixed order analysis"
echo "--- The ordering of couplings is assumed to be QCD, QED so that tag = QCD + 100* QED"
grep -m1 "the order of the coupling orders is" ${OUTDIR}/SubProcesses/*/orders.inc
cat << EOF > ${OUTDIR}/FixedOrderAnalysis/analysis_HwU_template.f
      subroutine analysis_begin(nwgt,weights_info)
      implicit none
      integer nwgt,i,l
      double precision pi
      parameter (pi=3.1415926535897932d0)
      character*(*) weights_info(*)
      character*8 cc(12)
      data cc/'|T@LO1','|T@LO2','|T@LO3','|T@LO4','|T@LO','|T@NLO1'
     & ,'|T@NLO2','|T@NLO3','|T@NLO4','|T@NLO5','|T@NLO','|T@FULL'/
      call HwU_inithist(nwgt,weights_info)
      do i=1,12
        l=(i-1)*57
         call HwU_book(l+ 1 , 'total rate             '//cc(i),1,0.5d0,1.5d0)
         call HwU_book(l+ 2 , 'HT sys                 '//cc(i),50,0d0,2500d0)
         call HwU_book(l+ 3 , 'HT sys (wE)            '//cc(i),50,0d0,2500d0)
         call HwU_book(l+ 4 , 'avg HT sys (wE)        '//cc(i),50,0d0,1000d0)
         call HwU_book(l+ 5 , 'inv mass 3t            '//cc(i),50,0d0,2500d0)
         call HwU_book(l+ 6 , 'inv mass tot           '//cc(i),50,0d0,3500d0)
         call HwU_book(l+ 7 , 'inv mass ttx1          '//cc(i),100,0d0,2000d0)
         call HwU_book(l+ 8 , 'inv mass ttx2          '//cc(i),100,0d0,2000d0)
         call HwU_book(l+ 9 , 'pT ttx1                '//cc(i),50,0d0,800d0)
         call HwU_book(l+10 , 'pT ttx2                '//cc(i),50,0d0,800d0)
         call HwU_book(l+11 , 'dr ttx1                '//cc(i),50,0d0,6d0)
         call HwU_book(l+12 , 'dr ttx2                '//cc(i),50,0d0,6d0)
         call HwU_book(l+13 , 'rap ttx1               '//cc(i),50,-2.8d0,2.8d0)
         call HwU_book(l+14 , 'rap ttx2               '//cc(i),50,-2.8d0,2.8d0)
         call HwU_book(l+15 , 'cos sc ang ttx1        '//cc(i),50,-1.0d0,1.0d0)
         call HwU_book(l+16 , 'cos sc ang ttx2        '//cc(i),50,-1.0d0,1.0d0)
         call HwU_book(l+17 , 'pT 1                   '//cc(i),50,0d0,800d0)
         call HwU_book(l+18 , 'pT 2                   '//cc(i),50,0d0,800d0)
         call HwU_book(l+19 , 'pT 3                   '//cc(i),50,0d0,800d0)
         call HwU_book(l+20 , 'pT t                   '//cc(i),50,0d0,800d0)
         call HwU_book(l+21 , 'pT tx1                 '//cc(i),50,0d0,800d0)
         call HwU_book(l+22 , 'pT tx2                 '//cc(i),50,0d0,800d0)
         call HwU_book(l+23 , 'eta 1                  '//cc(i),50,-5d0,5d0)
         call HwU_book(l+24 , 'eta 2                  '//cc(i),50,-5d0,5d0)
         call HwU_book(l+25 , 'eta 3                  '//cc(i),50,-5d0,5d0)
         call HwU_book(l+26 , 'eta t                  '//cc(i),50,-5d0,5d0)
         call HwU_book(l+27 , 'eta tx1                '//cc(i),50,-5d0,5d0)
         call HwU_book(l+28 , 'eta tx2                '//cc(i),50,-5d0,5d0)
         call HwU_book(l+29 , 'inv mass 12            '//cc(i),100,0d0,2000d0)
         call HwU_book(l+30 , 'inv mass 13            '//cc(i),100,0d0,2000d0)
         call HwU_book(l+31 , 'inv mass 23            '//cc(i),100,0d0,2000d0)
         call HwU_book(l+32 , 'dr 12                  '//cc(i),50,0d0,6d0)
         call HwU_book(l+33 , 'dr 13                  '//cc(i),50,0d0,6d0)
         call HwU_book(l+34 , 'dr 23                  '//cc(i),50,0d0,6d0)
         call HwU_book(l+35 , 'pT tt 12               '//cc(i),50,0d0,800d0)
         call HwU_book(l+36 , 'pT tt 13               '//cc(i),50,0d0,800d0)
         call HwU_book(l+37 , 'pT tt 23               '//cc(i),50,0d0,800d0)
         call HwU_book(l+38 , 'cos sc ang 12          '//cc(i),50,-1.0d0,1.0d0)
         call HwU_book(l+39 , 'cos sc ang 13          '//cc(i),50,-1.0d0,1.0d0)
         call HwU_book(l+40 , 'cos sc ang 23          '//cc(i),50,-1.0d0,1.0d0)
         call HwU_book(l+41 , 'rap tt 12              '//cc(i),50,-2.8d0,2.8d0)
         call HwU_book(l+42 , 'rap tt 13              '//cc(i),50,-2.8d0,2.8d0)
         call HwU_book(l+43 , 'rap tt 23              '//cc(i),50,-2.8d0,2.8d0)
         call HwU_book(l+44 , 'pT Wp                  '//cc(i),50,0d0,800d0)
         call HwU_book(l+45 , 'y 1                    '//cc(i),50,-5d0,5d0)
         call HwU_book(l+46 , 'y 2                    '//cc(i),50,-5d0,5d0)
         call HwU_book(l+47 , 'y 3                    '//cc(i),50,-5d0,5d0)
         call HwU_book(l+48 , 'y t                    '//cc(i),50,-5d0,5d0)
         call HwU_book(l+49 , 'y tx1                  '//cc(i),50,-5d0,5d0)
         call HwU_book(l+50 , 'y tx2                  '//cc(i),50,-5d0,5d0)
         call HwU_book(l+51 , 'y Wp                   '//cc(i),50,-5d0,5d0)
         call HwU_book(l+52 , 'eta Wp                 '//cc(i),50,-5d0,5d0)
         call HwU_book(l+53 , 'y jet                  '//cc(i),50,-5d0,5d0)
         call HwU_book(l+54 , 'y bottom               '//cc(i),50,-5d0,5d0)
         call HwU_book(l+55 , 'pT jet                 '//cc(i),50,0d0,1500d0)
         call HwU_book(l+56 , 'pT bottom              '//cc(i),50,0d0,1500d0)
         call HwU_book(l+57 , 'm wb                   '//cc(i),300,`echo "$TOPMASS - 160" | bc`d0,`echo "$TOPMASS - 160 + 1500" | bc`d0)
      enddo
      return
      end
      subroutine analysis_end(dummy)
      implicit none
      double precision dummy
      call HwU_write_file
      return                
      end
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      subroutine analysis_fill(p,istatus,ipdg,wgts,ibody)
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      implicit none
      include 'nexternal.inc'
      integer istatus(nexternal)
      integer iPDG(nexternal)
      double precision p(0:4,nexternal)
      double precision wgts(*)
      integer ibody,i,l,mu,nu
      integer ibottom,ijet,iw
      double precision var
      double precision pq3(0:3),pq4(0:3),pq5(0:3),pw(0:3)
      double precision pttx1(0:3),pttx2(0:3),ptot(0:3),p3t(0:3)
      double precision p1(0:3),p2(0:3),p3(0:3)
      double precision ptx1(0:3),ptx2(0:3)
      double precision p12(0:3),p13(0:3),p23(0:3)
      double precision pT1,pT2,pT3,pTtq,pTtxq1,pTtxq2
      double precision eta1,eta2,eta3,etat,etatx1,etatx2,etaWp
      double precision y1,y2,y3,yt,ytx1,ytx2,yWp,yjet,ybottom
      double precision pTttx1,pTttx2,ptbottom,ptjet
      double precision mttx1,mttx2,m3t,mtot,mwb
      double precision mtt12,mtt13,mtt23,dr12,dr13,dr23
      double precision drttx1,drttx2,yttx1,yttx2
      double precision pTtt12,pTtt13,pTtt23,ytt12,ytt13,ytt23
      double precision pTq3,pTq4,pTq5,pTw,sspT
      double precision sum_mt,sum_mt_avg,xm2,pt
      double precision scat_angle12,scat_angle13,scat_angle23
      double precision scat_anglettx1,scat_anglettx2
      double precision getrapidity,dot,getpseudorap,getptv4,getinvm,getdr,getcosv4 
      double precision p_bottom(0:3),p_jet(0:3),p_wb(0:3)
      double precision ycut,ptcut,tinyptcut
      external getrapidity,dot,getpseudorap,getptv4,getinvm,getdr,getcosv4
      double precision ptArray(1:3),ptxArray(1:2)
      integer quarkIds(1:3),quarkxIds(1:2)
      integer orders_tag_plot
      common /corderstagplot/ orders_tag_plot

      ijet=0
      ibottom=0
      iw=6               ! assumed to be last born-requested particle, start jet finding loop below from there
      ptjet=-1d0
      ptbottom=-1d0
      yjet=500d0
      ybottom=500d0
      mwb = -1d0

      do i=iw+1, nexternal
        if (ipdg(i).eq.21.or.(abs(ipdg(i)).ge.1.and.abs(ipdg(i)).le.5)) ijet=i
        if (abs(ipdg(i)).eq.5) ibottom=i
      enddo
      
      if (ijet.ne.0) then
        do mu=0,3
           p_jet(mu)=p(mu,ijet)
        enddo
        ptjet=getptv4(p_jet)
        yjet=getrapidity(p_jet(0),p_jet(3))
      endif
      
      if (ibottom.ne.0) then
        do nu=0,3
          p_bottom(nu)=p(nu,ibottom)
        enddo
        ptbottom=getptv4(p_bottom)
        ybottom=getrapidity(p_bottom(0),p_bottom(3))
      endif
      
      if (ibottom.ne.0.and.iw.ne.0) then
        do nu=0,3
          p_wb(nu) = p(nu,ibottom) + p(nu,iw)
        enddo
        mwb = getinvm(p_wb(0),p_wb(1),p_wb(2),p_wb(3))
      endif

      do i=0,3
         pq3(i)  = p(i,3) !top
         pq4(i)  = p(i,4) !anti-top
         pq5(i)  = p(i,5) !anti-top
         pw(i)   = p(i,iw) !w
         p3t(i)  = pq3(i) + pq4(i) + pq5(i)
         ptot(i) = pq3(i) + pq4(i) + pq5(i) + pw(i)
      enddo

      pTq3 = getptv4(pq3)
      pTq4 = getptv4(pq4) 
      pTq5 = getptv4(pq5) 
      pTw = getptv4(pw) 
      sspT = pTq3 + pTq4 + pTq5 + pTw 
      m3t = getinvm(p3t(0),p3t(1),p3t(2),p3t(3))
      mtot = getinvm(ptot(0),ptot(1),ptot(2),ptot(3))

      sum_mt=0
      do i=nincoming+1,nexternal
        xm2=dot(p(0,i),p(0,i))
        if(xm2.le.0.d0)xm2=0.d0
        pt=dsqrt(p(1,i)**2 + p(2,i)**2)
        sum_mt=sum_mt+sqrt(pt**2+xm2)
      enddo
      sum_mt_avg=sum_mt/4d0

      ptArray=[pTq3,pTq4,pTq5]
      quarkIds=[3,4,5]

      ptxArray=[pTq4,pTq5]
      quarkxIds=[4,5]

      call sortpt3(ptArray,quarkIds)
      call sortpt2(ptxArray,quarkxIds)

      do i = 0,3 
         p1(i) = p(i,quarkIds(1))
         p2(i) = p(i,quarkIds(2))
         p3(i) = p(i,quarkIds(3))
         ptx1(i) = p(i,quarkxIds(1))
         ptx2(i) = p(i,quarkxIds(2))
         p12(i) = p1(i) + p2(i)
         p13(i) = p1(i) + p3(i)
         p23(i) = p2(i) + p3(i)
         pttx1(i) = pq3(i)+ptx1(i)
         pttx2(i) = pq3(i)+ptx2(i)
      enddo
      mttx1 = getinvm(pttx1(0),pttx1(1),pttx1(2),pttx1(3))
      mttx2 = getinvm(pttx2(0),pttx2(1),pttx2(2),pttx2(3))
      pTttx1 = getptv4(pttx1)
      pTttx2 = getptv4(pttx2) 
      pT1 = getptv4(p1)
      pT2 = getptv4(p2)
      pT3 = getptv4(p3)
      pTtq = getptv4(pq3)
      pTtxq1 = getptv4(ptx1)
      pTtxq2 = getptv4(ptx2)
      eta1 = getpseudorap(p1(0),p1(1),p1(2),p1(3))
      y1 = getrapidity(p1(0),p1(3))
      eta2 = getpseudorap(p2(0),p2(1),p2(2),p2(3))
      y2 = getrapidity(p2(0),p2(3))
      eta3 = getpseudorap(p3(0),p3(1),p3(2),p3(3))
      y3 = getrapidity(p3(0),p3(3))
      etat = getpseudorap(pq3(0),pq3(1),pq3(2),pq3(3))
      yt = getrapidity(pq3(0),pq3(3))
      etatx1 = getpseudorap(ptx1(0),ptx1(1),ptx1(2),ptx1(3))
      ytx1 = getrapidity(ptx1(0),ptx1(3))
      etatx2 = getpseudorap(ptx2(0),ptx2(1),ptx2(2),ptx2(3))
      ytx2 = getrapidity(ptx2(0),ptx2(3))
      mtt12 = getinvm(p12(0),p12(1),p12(2),p12(3))
      mtt13 = getinvm(p13(0),p13(1),p13(2),p13(3))
      mtt23 = getinvm(p23(0),p23(1),p23(2),p23(3))
      pTtt12 = getptv4(p12)
      pTtt13 = getptv4(p13)
      pTtt23 = getptv4(p23)
      dr12 = getdr(p1(0),p1(1),p1(2),p1(3),p2(0),p2(1),p2(2),p2(3))
      dr13 = getdr(p1(0),p1(1),p1(2),p1(3),p3(0),p3(1),p3(2),p3(3))
      dr23 = getdr(p2(0),p2(1),p2(2),p2(3),p3(0),p3(1),p3(2),p3(3))
      scat_angle12 = getcosv4(p1,p2)
      scat_angle13 = getcosv4(p1,p3)
      scat_angle23 = getcosv4(p2,p3)
      ytt12 = getrapidity(p12(0),p12(3))
      ytt13 = getrapidity(p13(0),p13(3))
      ytt23 = getrapidity(p23(0),p23(3))
      drttx1 = getdr(pq3(0),pq3(1),pq3(2),pq3(3),ptx1(0),ptx1(1),ptx1(2),ptx1(3))
      drttx2 = getdr(pq3(0),pq3(1),pq3(2),pq3(3),ptx2(0),ptx2(1),ptx2(2),ptx2(3))
      scat_anglettx1 = getcosv4(pq3,ptx1)
      scat_anglettx2 = getcosv4(pq3,ptx2)
      yttx1 = getrapidity(pttx1(0),pttx1(3))
      yttx2 = getrapidity(pttx2(0),pttx2(3))
      etaWp = getpseudorap(pw(0),pw(1),pw(2),pw(3))
      yWp = getrapidity(pw(0),pw(3))

      ycut=2.5d0
      ptcut=30.d0
      tinyptcut=$TINYPTCUT

      var=1d0
      do i=1,12
       l=(i-1)*57
c veto switch
c start veto
       if (ptbottom.lt.ptcut.or.abs(ybottom).gt.ycut) then
c else veto
       if (1.eq.1) then
c end veto
       if (mod(i,12).eq.1.and.orders_tag_plot.ne.206) cycle
       if (mod(i,12).eq.2.and.orders_tag_plot.ne.404) cycle
       if (mod(i,12).eq.3.and.orders_tag_plot.ne.602) cycle
       if (mod(i,12).eq.4.and.orders_tag_plot.ne.800) cycle
       if (mod(i,12).eq.5.and.orders_tag_plot.ne.206  
     &.and.orders_tag_plot.ne.404
     &.and.orders_tag_plot.ne.602
     &.and.orders_tag_plot.ne.800) cycle
       if (mod(i,12).eq.6.and.orders_tag_plot.ne.208) cycle
       if (mod(i,12).eq.7.and.orders_tag_plot.ne.406) cycle
       if (mod(i,12).eq.8.and.orders_tag_plot.ne.604) cycle
       if (mod(i,12).eq.9.and.orders_tag_plot.ne.802) cycle
       if (mod(i,12).eq.10.and.orders_tag_plot.ne.1000) cycle
       if (mod(i,12).eq.11.and.orders_tag_plot.ne.208  
     &.and.orders_tag_plot.ne.406
     &.and.orders_tag_plot.ne.604
     &.and.orders_tag_plot.ne.802
     &.and.orders_tag_plot.ne.1000) cycle
       if (mod(i,12).eq.0.and.orders_tag_plot.ne.206  
     &.and.orders_tag_plot.ne.404
     &.and.orders_tag_plot.ne.602
     &.and.orders_tag_plot.ne.800
     &.and.orders_tag_plot.ne.208
     &.and.orders_tag_plot.ne.406
     &.and.orders_tag_plot.ne.604
     &.and.orders_tag_plot.ne.802
     &.and.orders_tag_plot.ne.1000) cycle
       call HwU_fill(l+1,var,wgts)
       call HwU_fill(l+2,sspT,wgts)
       call HwU_fill(l+3,sum_mt,wgts)
       call HwU_fill(l+4,sum_mt_avg,wgts)
       call HwU_fill(l+5,m3t,wgts)
       call HwU_fill(l+6,mtot,wgts)
       call HwU_fill(l+7,mttx1,wgts)
       call HwU_fill(l+8,mttx2,wgts)
       call HwU_fill(l+9,pTttx1,wgts)
       call HwU_fill(l+10,pTttx2,wgts)
       call HwU_fill(l+11,drttx1,wgts)
       call HwU_fill(l+12,drttx2,wgts)
       call HwU_fill(l+13,yttx1,wgts)
       call HwU_fill(l+14,yttx2,wgts)
       call HwU_fill(l+15,scat_anglettx1,wgts)
       call HwU_fill(l+16,scat_anglettx2,wgts)
       call HwU_fill(l+17,pT1,wgts)
       call HwU_fill(l+18,pT2,wgts)
       call HwU_fill(l+19,pT3,wgts)
       call HwU_fill(l+20,pTtq,wgts)
       call HwU_fill(l+21,pTtxq1,wgts)
       call HwU_fill(l+22,pTtxq2,wgts)
       call HwU_fill(l+23,eta1,wgts)
       call HwU_fill(l+24,eta2,wgts)
       call HwU_fill(l+25,eta3,wgts)
       call HwU_fill(l+26,etat,wgts)
       call HwU_fill(l+27,etatx1,wgts)
       call HwU_fill(l+28,etatx2,wgts)
       call HwU_fill(l+29,mtt12,wgts)
       call HwU_fill(l+30,mtt13,wgts)
       call HwU_fill(l+31,mtt23,wgts)
       call HwU_fill(l+32,dr12,wgts)
       call HwU_fill(l+33,dr13,wgts)
       call HwU_fill(l+34,dr23,wgts)
       call HwU_fill(l+35,pTtt12,wgts)
       call HwU_fill(l+36,pTtt13,wgts)
       call HwU_fill(l+37,pTtt23,wgts)
       call HwU_fill(l+38,scat_angle12,wgts)
       call HwU_fill(l+39,scat_angle13,wgts)
       call HwU_fill(l+40,scat_angle23,wgts)
       call HwU_fill(l+41,ytt12,wgts)
       call HwU_fill(l+42,ytt13,wgts)
       call HwU_fill(l+43,ytt23,wgts)
       call HwU_fill(l+44,pTw,wgts)
       call HwU_fill(l+45,y1,wgts)
       call HwU_fill(l+46,y2,wgts)
       call HwU_fill(l+47,y3,wgts)
       call HwU_fill(l+48,yt,wgts)
       call HwU_fill(l+49,ytx1,wgts)
       call HwU_fill(l+50,ytx2,wgts)
       call HwU_fill(l+51,yWp,wgts)
       call HwU_fill(l+52,etaWp,wgts)
       if (ijet.ne.0
     & .and. ptjet.gt.tinyptcut ) then
       call HwU_fill(l+53,yjet,wgts)
       call HwU_fill(l+55,ptjet,wgts)
       endif
       if (ibottom.ne.0
     & .and. ptbottom.gt.tinyptcut ) then
       call HwU_fill(l+54,ybottom,wgts)
       call HwU_fill(l+56,ptbottom,wgts)
       if (iw.ne.0) call HwU_fill(l+57,mwb,wgts)
       endif
      endif
      enddo
999   return
      end

      subroutine sortpt3(ptArray,quarkIds)
      implicit none
      real*8 ptArray(1:3),tempPt
      integer quarkIds(1:3),i,j,tempId
      do i= 1, size(ptArray)-1
          do j = 1, size(ptArray)-i
              if(ptArray(j) < ptArray(j+1)) then
                      tempPt = ptArray(j)
                      ptArray(j) = ptArray(j+1)
                      ptArray(j+1) = tempPt
                      tempId = quarkIds(j)
                      quarkIds(j) = quarkIds(j+1)
                      quarkIds(j+1) = tempId
              endif
          enddo       
      enddo
      end subroutine sortpt3

      subroutine sortpt2(ptArray,quarkIds)
      implicit none
      real*8 ptArray(1:2),tempPt
      integer quarkIds(1:2),i,j,tempId
      do i= 1, size(ptArray)-1
          do j = 1, size(ptArray)-i
              if(ptArray(j) < ptArray(j+1)) then
                      tempPt = ptArray(j)
                      ptArray(j) = ptArray(j+1)
                      ptArray(j+1) = tempPt
                      tempId = quarkIds(j)
                      quarkIds(j) = quarkIds(j+1)
                      quarkIds(j+1) = tempId
              endif
          enddo       
      enddo
      end subroutine sortpt2

      function getinvm(en,ptx,pty,pl)
      implicit none
      real*8 getinvm,en,ptx,pty,pl,tiny,tmp
      parameter (tiny=1.d-5)
c
      tmp=en**2-ptx**2-pty**2-pl**2
      if(tmp.gt.0.d0)then
        tmp=sqrt(tmp)
      elseif(tmp.gt.-tiny)then
        tmp=0.d0
      else
        write(*,*)'Attempt to compute a negative mass'
        stop
      endif
      getinvm=tmp
      return
      end

      function getptv4(p)
      implicit none
      real*8 getptv4,p(0:3)
      getptv4=sqrt(p(1)**2+p(2)**2)
      return
      end

      function getrapidity(en,pl)
      implicit none
      real*8 getrapidity,en,pl,tiny,xplus,xminus,y
      parameter (tiny=1.d-8)
      xplus=en+pl
      xminus=en-pl
      if(xplus.gt.tiny.and.xminus.gt.tiny)then
         if( (xplus/xminus).gt.tiny.and.(xminus/xplus).gt.tiny)then
            y=0.5d0*log( xplus/xminus  )
         else
            y=sign(1.d0,pl)*1.d8
         endif
      else 
         y=sign(1.d0,pl)*1.d8
      endif
      getrapidity=y
      return
      end

      function getdrv(p1,p2)
      implicit none
      real*8 getdrv,p1(0:3),p2(0:3)
      real*8 getdr
c
      getdrv=getdr(p1(0),p1(1),p1(2),p1(3),
     #             p2(0),p2(1),p2(2),p2(3))
      return
      end

      function getdr(en1,ptx1,pty1,pl1,en2,ptx2,pty2,pl2)
      implicit none
      real*8 getdr,en1,ptx1,pty1,pl1,en2,ptx2,pty2,pl2,deta,dphi,
     # getpseudorap,getdelphi
c
      deta=getpseudorap(en1,ptx1,pty1,pl1)-
     #     getpseudorap(en2,ptx2,pty2,pl2)
      dphi=getdelphi(ptx1,pty1,ptx2,pty2)
      getdr=sqrt(dphi**2+deta**2)
      return
      end

      function getdelphi(ptx1,pty1,ptx2,pty2)
      implicit none
      real*8 getdelphi,ptx1,pty1,ptx2,pty2,tiny,pt1,pt2,tmp
      parameter (tiny=1.d-5)
c
      pt1=sqrt(ptx1**2+pty1**2)
      pt2=sqrt(ptx2**2+pty2**2)
      if(pt1.ne.0.d0.and.pt2.ne.0.d0)then
        tmp=ptx1*ptx2+pty1*pty2
        tmp=tmp/(pt1*pt2)
        if(abs(tmp).gt.1.d0+tiny)then
          write(*,*)'Cosine larger than 1'
          stop
        elseif(abs(tmp).ge.1.d0)then
          tmp=sign(1.d0,tmp)
        endif
        tmp=acos(tmp)
      else
        tmp=1.d8
      endif
      getdelphi=tmp
      return
      end

      function getcosv4(q1,q2)
      implicit none
      real*8 getcosv4,q1(0:3),q2(0:3)
      real*8 xnorm1,xnorm2,tmp
c
      if(q1(0).lt.0.d0.or.q2(0).lt.0.d0)then
        getcosv4=-1.d10
        return
      endif
      xnorm1=sqrt(q1(1)**2+q1(2)**2+q1(3)**2)
      xnorm2=sqrt(q2(1)**2+q2(2)**2+q2(3)**2)
      if(xnorm1.lt.1.d-6.or.xnorm2.lt.1.d-6)then
        tmp=-1.d10
      else
        tmp=q1(1)*q2(1)+q1(2)*q2(2)+q1(3)*q2(3)
        tmp=tmp/(xnorm1*xnorm2)
        if(abs(tmp).gt.1.d0.and.abs(tmp).le.1.001d0)then
          tmp=sign(1.d0,tmp)
        elseif(abs(tmp).gt.1.001d0)then
          write(*,*)'Error in getcosv4',tmp
          stop
        endif
      endif
      getcosv4=tmp
      return
      end

      function getpseudorap(en,ptx,pty,pl)
      implicit none
      real*8 getpseudorap,en,ptx,pty,pl,tiny,pt,eta,th
      parameter (tiny=1.d-5)
c
      pt=sqrt(ptx**2+pty**2)
      if(pt.lt.tiny.and.abs(pl).lt.tiny)then
        eta=sign(1.d0,pl)*1.d8
      else
        th=atan2(pt,pl)
        eta=-log(tan(th/2.d0))
      endif
      getpseudorap=eta
      return
      end
EOF

## remove veto if needed
date && echo "--- Remove veto if needed"
if [[ "$VETO" == "" ]] ; then
	sed -i '/c start veto/,/c else veto/d' ${OUTDIR}/FixedOrderAnalysis/analysis_HwU_template.f
else
	sed -i '/c else veto/,/c end veto/d' ${OUTDIR}/FixedOrderAnalysis/analysis_HwU_template.f
fi
date && echo "--- Grep that"
grep -A3 "c veto switch" ${OUTDIR}/FixedOrderAnalysis/analysis_HwU_template.f



### transfer 
date && echo "--- Transfer"
$TRANSFER

### launch
# (the matrix_x.o files should be recompiled automatically)
date && echo "--- Launching"
RUNNAME=run_${OUTDIR}_${EBEAM}_istr${ISTR}_scale${SCALEFAC}${VETO}_precision${PRECISION}_bwcutoff${BWCUTOFF}
echo "${INIT}
set lhapdf $LHAPDF/bin/lhapdf-config
launch NLO --name=$RUNNAME
set ebeam1           $EBEAM           #
set ebeam2           $EBEAM           #
set ptj              0.               # no cuts
set MT               $TOPMASS         # adjust the m(Wb) binning according to mass and BWCUTOFF
set ymt              $TOPMASS         #
set decay 6          $TOPWIDTH        # dummy top width to control DRW      
set decay 24         $WWIDTH          # for the tttj case, will be reset automatically to zero in tttw
set bwcutoff         $BWCUTOFF        #
set istr             $ISTR            #
set MW               80.379           #
set MZ               91.1876
set GF               1.166390e-05
set MH               125.             #
set decay 15         0.
set decay 23         0.
set decay 25         0.
set req_acc_fo       $PRECISION       # computational cost is quadratic in the precision
set dynamical_scale_choice 3          # -1 and 3 are the same in MG5_aMC but not in MG5_LO 
set pdlabel          lhapdf           #
set lhaid            324900,93300,325300,335900       
# 324900:NNPDF31_nlo_as_0118_luxqed
# 335900:NNPDF40_nlo_as_01180_qed
# 325300:NNPDF31_nnlo_as_0118_mc_hessian_pdfas
# 93300:PDF4LHC21_40_pdfas
# 331700:NNPDF40_nlo_as_01180
# 335900:NNPDF40_nlo_as_01180_qed
# 260000:NNPDF30_nlo_as_0118
set reweight_pdf     True,True,True,True        # list of the same length as lhaid
set fixed_ren_scale  False            #
set fixed_fac_scale  False            #
set mur_over_ref     $SCALEFAC
set muf_over_ref     $SCALEFAC
set reweight_scale   True
set rw_rscale 0.25,0.354,0.5,0.707,1.,1.414,2.,2.828,4.      # factor of four variations by reweighting
set rw_fscale 0.25,0.354,0.5,0.707,1.,1.414,2.,2.828,4.
0" > ${OUTDIR}.cmd
### MadSTR has to be ran from within the directory
time ${OUTDIR}/bin/aMCatNLO ${OUTDIR}.cmd

### transfer 
date && echo "--- Transfer"
$TRANSFER


### get histogram information
date && echo "--- Get histogram information"

# save the total rate histograms here
SUMMARY=summary.HwU

# get total rates from HwU file
HWU=$OUTDIR/Events/$RUNNAME/MADatNLO.HwU
echo "--- Feching histogram from $HWU"
	
if [[ ! -f "$SUMMARY" ]] ; then
	echo "--- Adding header to $SUMMARY"
	head -n1 $HWU > $SUMMARY
fi

if [ "$PROC" = "wbqq" ] ; then
sed -n -e "/m wb.*TYPE@${NLO}${ORDER}/,/histogram>/p" $HWU | sed -e "s/m wb/ttt${PROC}, $EBEAM, $VETO/" >> $SUMMARY
else
grep -A2 "total rate.*TYPE@${NLO}${ORDER}" $HWU | sed "s/total rate/ttt${PROC}, $EBEAM, $VETO/" >> $SUMMARY
fi

### get histogram information
date && echo "--- Display rate summary"

VARIOUS=$MGBASE/madgraph/various
PYCODE=summary.py

cat << EOF > $PYCODE
import sys
import numpy as np
here = '$VARIOUS/'
if here not in sys.path:
    sys.path.append(here)
import histograms as hist

# the histogram file
file = hist.HwUList('$SUMMARY')

# histogram names
names = file.get_hist_names()

# weight names
entries = file.get_wgt_names()

# make an array out of each order
data = {}
for name in names:
    h = file.get(name)
    if 'tttwbqq' in name:
        binstarts =  np.array([b.boundaries[0] for b in file.get(name).bins])-$TOPMASS
        selbins   = (binstarts<-$WINDOW) + (binstarts>=$WINDOW)
        data[tuple(name.replace(' ','').split(','))] = np.array([np.sum(np.array(h.get(entry))[selbins]) for entry in entries])
    else:
        data[tuple(name.replace(' ','').split(','))] = np.array([h.get(entry)[0] for entry in entries])


# the various pdfs
allpdfs = list(set([entry[2] for entry in entries if entry[0]=='pdf_adv']))

# display reference pdf first
refpdf = 'PDF4LHC21_40_pdfas'
if refpdf in allpdfs:
    allpdfs.pop(allpdfs.index(refpdf))
    allpdfs = [refpdf]+allpdfs

# index of weighs for each pdf
ipdf = {}
for pdf in allpdfs:
    ipdf[pdf] = [i for i in range(len(entries))
             if entries[i][0]=='pdf_adv'
             and entries[i][2]==pdf]


# convert from pb to fb
fac = 1e3

# central scale
scale = 1.                  # 1. just keeps the central scale with which the run was performed
central = ('scale_adv', 3, scale, scale)
icentral = entries.index(central)


# the various scale variation
keys = [key for key in entries 
        if isinstance(key,tuple)
        and key[0] == 'scale_adv'
        and key[1] == 3
        and key[2] in [1.*scale,.5*scale,2.*scale]
        and key[3] in [1.*scale,.5*scale,2.*scale]
        and key[2]/key[3]<4 and key[3]/key[2]<4 # seven points
       ]
ikeys = [entries.index(key) for key in keys]


# index of statistical error
ierr = entries.index('stat_error')

# square the error
for run in data:
    data[run][ierr] *= data[run][ierr]


# sum components
for energy in ['6500.', '6800.', '7000.']:
    try:
        data[('tttwp', energy, '', 'LO')] = \
            data[('tttwp', energy, '', 'LO1')] + \
            data[('tttwp', energy, '', 'LO2')] + \
            data[('tttwp', energy, '', 'LO3')]
    except KeyError as error:
        pass
        
    for veto in ['','veto']:
        try:
            data[('tttwp', energy, veto, 'NLO QCD')] = \
                data[('tttwp', energy, '', 'LO1')] + \
                data[('tttwp', energy, veto, 'NLO1')]
        except KeyError as error:
            pass
        try:
            data[('tttwp', energy, veto, 'NLO QCD + qq')] = \
                data[('tttwp', energy, veto, 'NLO QCD')] + \
                data[('tttwbqq', energy, '', 'NLO1')]
        except KeyError as error:
            pass
        
        try:
            data[('tttwp', energy, veto, 'LO + NLO1')] = \
                data[('tttwp', energy, '', 'LO')] + \
                data[('tttwp', energy, veto, 'NLO1')]
        except KeyError as error:
            pass
            
        try:
            data[('tttwp', energy, veto, 'LO + NLO1 + qq')] = \
                data[('tttwp', energy, veto, 'LO + NLO1')] + \
                data[('tttwbqq', energy, '', 'NLO1')]
        except KeyError as error:
            pass
    
    # the labels of orders are different for tttj
    for proc in ['tttjp', 'tttjm']:
        
        try:
            data[(proc, energy, '', 'LO')] = \
                data[(proc, energy, '', 'LO2')] + \
                data[(proc, energy, '', 'LO3')] + \
                data[(proc, energy, '', 'LO4')]
        except KeyError as error:
            pass
            
        for veto in ['','veto']:
            try:
                data[(proc, energy, veto, 'NLO QCD')] = \
                    data[(proc, energy, '', 'LO2')] + \
                    data[(proc, energy, veto, 'NLO2')]
            except KeyError as error:
                pass
            
            try:
                data[(proc, energy, veto, 'LO + NLO1')] = \
                    data[(proc, energy, '', 'LO')] + \
                    data[(proc, energy, veto, 'NLO2')]
            except KeyError as error:
                pass
            
    
# square root of the error squared
for run in data:
    data[run][ierr] = np.sqrt(data[run][ierr])

    
# display results
for run in data:
    
#    if run[-1] not in ['LO + NLO1']: #['LO1']: #['NLO QCD']:#['LO', 'LO + NLO1']:
#        continue
    
    # central value with default PDF
    y = data[run][icentral]*fac
    
    # scale uncertainty
    s = np.array(data[run])[ikeys]*fac
    u = np.max(s)
    d = np.min(s)
    
    # statistical uncertainty
    e = data[run][ierr]*fac
    
    
    
    print('---')
    label = '{:}, {:g} TeV, {:} {:}'.format(run[0],float(run[1])/500, run[3], run[2])
    
    
    # only scale variation
    print('{:37}\t {:+5.2g}% {:+5.2g}% (scales)\t\t (±{:4.1g}% stat)'.format(
            label,
            (u/y-1)*100,(d/y-1)*100,        # scales
            e/abs(y)*100                    # statistics
        ))
    
    # also display results for other pdfs
    for pdf in allpdfs:
            
        # case with aS variation
        if '_pdfas' in pdf:

            # pdf variation
            cp = data[run][ipdf[pdf][0]]                  # central value
            vp = data[run][ipdf[pdf][1:-2]]               # variations
            ep = np.sqrt(np.sum((vp-cp)**2))/cp*100

            ## aS variation
            da = (data[run][ipdf[pdf][-2]]/cp-1)*100
            ua = (data[run][ipdf[pdf][-1]]/cp-1)*100

            print('{:37}\t{:#6.3g} fb\t ±{:<#3.2g}% (pdf)   {:+5.2g}% {:+5.2g}% (aS)   -{:<#3.2g}% +{:<#3.2g}% (pdf+aS)'.format(
                pdf,
                cp*fac,                         # take the central value corresponding to that pdf
                ep,                             # pdf
                da, ua,                         # aS
                np.sqrt(ep**2+da**2),np.sqrt(ep**2+ua**2)   # pdf+aS
#                 np.sqrt(ep**2+((ua-da)/2)**2)   # tot
            ))

        # case without aS variation
        else:

            # pdf variation
            cp = data[run][ipdf[pdf][0]]                  # central value
            vp = data[run][ipdf[pdf][1:]]                 # variations
            ep = np.sqrt(np.sum((vp-cp)**2)/len(vp))/cp*100

            print('{:37}\t{:#6.3g} fb\t ±{:<#3.2g}% (pdf)'.format(
                pdf,
                cp*fac,                         # take the central value corresponding to that pdf
                ep                              # pdf
            ))
EOF
$PYTHON "$PYCODE"   ### running python


### finalise 
date && echo "--- Done"
$TRANSFER

done
done
done
done
done
done
done
done

