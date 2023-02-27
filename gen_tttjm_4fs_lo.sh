#!/usr/bin/bash

OUTDIR=gen_tttjm_4fs_lo
exec >> ${OUTDIR}.log  2>&1

# need to specify python3.8 for CS8, while CS9 has python3.9 as default already
PYTHON=python3.8

### get MG 341
#date
#wget -O mg5.tar.gz https://launchpad.net/mg5amcnlo/3.0/3.4.x/+download/MG5_aMC_v3.4.1.tar.gz
#MG="python3 `tar tzf mg5.tar.gz | grep mg5_aMC`"
#tar xzf mg5.tar.gz

MG="$PYTHON $HOME/tools/mg5amcnlo_cs8/bin/mg5_aMC"
echo "--- Using MG executable: $MG"

### get lhapdf6
#date
#echo "install lhapdf6
#" > ${OUTDIR}.cmd
#$MG -f ${OUTDIR}.cmd
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PWD/`find ./ -type d -name "lhapdf6*"`/lib/

# need to point to LHAPDF (required for systematics reweighting)
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/tools/mg5amcnlo_cs8/HEPTools/lhapdf6_py3/lib/
echo "--- Using LD_LIBRARY_PATH: $LD_LIBRARY_PATH"

### get model
MODEL=loop_qcd_qed_sm-with_b_mass

for FIXEDSCALE in False True ; do


### generate
echo "set auto_convert_model T          # convert model to python3 automatically
import model ${MODEL}
set complex_mass_scheme True            # not actually needed if resonance width hardcoded
generate p p > t t t~ b~ j
output ${OUTDIR}
y# just in case some installation or overwritting is needed
" > ${OUTDIR}.cmd
if [[ ! -d "${OUTDIR}" ]] ; then
	date
	echo "--- Generate and output"
	time $MG -f ${OUTDIR}.cmd
fi


### launch
date
echo "launch ${OUTDIR}
done
set aEWM1 1.289300e+02
set MZ 9.118800e+01
set MW 8.041900e+01
set MT 173.3
set MB 4.7
set ptj 10.
set ptb 0.
set etaj -1.
set etab -1.
set drbj 0.                              # 0.7 corresponds to default jet radius at NLO
set pdlabel lhapdf
set lhaid 244600
set WW   0.  # 2.084650                  # irrelevant at LO
set WT   0.  # 1.36728
set dynamical_scale_choice 3             # -1 and 3 are the same at MG5_aMC but not in MG5_LO
set fixed_ren_scale $FIXEDSCALE          # those two actually determine fixed vs dyn scale
set fixed_fac_scale $FIXEDSCALE          # those two actually determine fixed vs dyn scale
set scale 519.9                          # 3*mt = 3*173.3 = 519.9 GeV
set dsqrt_q2fact1 519.9
set dsqrt_q2fact2 519.9
set scalefact 1.
set use_syst True
set systematics_program systematics
set systematics_arguments ['--mur=0.125,0.149,0.177,0.21,0.25,0.297,0.354,0.42,0.5,0.595,0.707,0.841,1,1.19,1.41,1.68,2,2.38,2.83,3.36,4,4.76,5.66,6.73,8', '--muf=0.125,0.149,0.177,0.21,0.25,0.297,0.354,0.42,0.5,0.595,0.707,0.841,1,1.19,1.41,1.68,2,2.38,2.83,3.36,4,4.76,5.66,6.73,8', '--pdf=central', '--together=mur,muf', '--dyn=-1']
0" > ${OUTDIR}.cmd
time $MG -f ${OUTDIR}.cmd

date

done

### results should be the following, for dynamical scale 3:
#  === Results Summary for run: run_06 tag: tag_1 ===
#     Cross-section :   0.0003013 +- 8.032e-07 pb
#     Nb of events :  10000
#INFO: # Events generated with PDF: NNPDF23_nlo_as_0118_qed (244600) 
#INFO: # Will Compute 624 weights per event. 
#INFO: #***************************************************************************
## original cross-section: 0.00030086401879635
##     scale variation: +222% -59.3%

