#!/usr/bin/bash

OUTDIR=gen_tttwp
exec >> ${OUTDIR}.log  2>&1

# need to specify python3.8 for CS8, while CS9 has python3.9 as default already
PYTHON=python3.8

### get MG 341
#date
#wget -O mg5.tar.gz https://launchpad.net/mg5amcnlo/3.0/3.4.x/+download/MG5_aMC_v3.4.1.tar.gz
#MG="python3 `tar tzf mg5.tar.gz | grep mg5_aMC`"
#tar xzf mg5.tar.gz

MG="$PYTHON $HOME/tools/mg5amcnlo/bin/mg5_aMC"
echo "--- Using MG executable: $MG"

### get lhapdf6
#date
#echo "install lhapdf6
#" > ${OUTDIR}.cmd
#$MG -f ${OUTDIR}.cmd
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PWD/`find ./ -type d -name "lhapdf6*"`/lib/

# need to point to LHAPDF (required for systematics reweighting)
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/tools/mg5amcnlo/HEPTools/lhapdf6_py3/lib/
echo "--- Using LD_LIBRARY_PATH: $LD_LIBRARY_PATH"

### get model
MODEL=loop_qcd_qed_sm                   # should automatically use 5FS


### get patch
PATCH="--- ${OUTDIR}/SubProcesses/P0_gbx_ttxtxwp/matrix_5.f    2023-02-21 18:06:27.000000001 +0100
+++ ${OUTDIR}/SubProcesses/P0_gbx_ttxtxwp/matrix_5.f    2023-02-21 18:06:27.000000001 +0100
@@ -486,7 +486,8 @@
       CALL FFV1_0(W(1,16),W(1,7),W(1,9),GC_11,AMP(4))
 C     Amplitude(s) for diagram number 5
       CALL FFV1_0(W(1,14),W(1,12),W(1,9),GC_11,AMP(5))
-      CALL FFV2_1(W(1,7),W(1,6),GC_124,DCMPLX(CMASS_MDL_MT),W(1,16))
+      CALL FFV2_1(W(1,7),W(1,6),1.0D-05*GC_124,DCMPLX(173.3,-0.6836),
+     $   W(1,16))
 C     Amplitude(s) for diagram number 6
       CALL FFV1_0(W(1,5),W(1,16),W(1,15),GC_11,AMP(6))
 C     Amplitude(s) for diagram number 7
--- ${OUTDIR}/SubProcesses/P0_gbx_ttxtxwp/matrix_6.f    2023-02-21 18:06:27.000000001 +0100
+++ ${OUTDIR}/SubProcesses/P0_gbx_ttxtxwp/matrix_6.f    2023-02-21 18:06:27.000000001 +0100
@@ -558,7 +558,8 @@
       CALL FFV1_0(W(1,16),W(1,7),W(1,9),GC_11,AMP(4))
 C     Amplitude(s) for diagram number 5
       CALL FFV1_0(W(1,14),W(1,12),W(1,9),GC_11,AMP(5))
-      CALL FFV2_1(W(1,7),W(1,6),GC_124,DCMPLX(CMASS_MDL_MT),W(1,16))
+      CALL FFV2_1(W(1,7),W(1,6),1.0D-05*GC_124,DCMPLX(173.3,-0.6836),
+     $   W(1,16))
 C     Amplitude(s) for diagram number 6
       CALL FFV1_0(W(1,5),W(1,16),W(1,15),GC_11,AMP(6))
 C     Amplitude(s) for diagram number 7
--- ${OUTDIR}/SubProcesses/P0_bxg_ttxtxwp/matrix_2.f    2023-02-21 18:06:27.000000001 +0100
+++ ${OUTDIR}/SubProcesses/P0_bxg_ttxtxwp/matrix_2.f    2023-02-21 18:06:27.000000001 +0100
@@ -558,7 +558,8 @@
       CALL FFV1_0(W(1,16),W(1,7),W(1,9),GC_11,AMP(4))
 C     Amplitude(s) for diagram number 5
       CALL FFV1_0(W(1,14),W(1,12),W(1,9),GC_11,AMP(5))
-      CALL FFV2_1(W(1,7),W(1,6),GC_124,DCMPLX(CMASS_MDL_MT),W(1,16))
+      CALL FFV2_1(W(1,7),W(1,6),1.0D-05*GC_124,DCMPLX(173.3,-0.6836),
+     $   W(1,16))
 C     Amplitude(s) for diagram number 6
       CALL FFV1_0(W(1,5),W(1,16),W(1,15),GC_11,AMP(6))
 C     Amplitude(s) for diagram number 7
--- ${OUTDIR}/SubProcesses/P0_bxg_ttxtxwp/matrix_6.f    2023-02-21 18:06:27.000000001 +0100
+++ ${OUTDIR}/SubProcesses/P0_bxg_ttxtxwp/matrix_6.f    2023-02-21 18:06:27.000000001 +0100
@@ -486,7 +486,8 @@
       CALL FFV1_0(W(1,16),W(1,7),W(1,9),GC_11,AMP(4))
 C     Amplitude(s) for diagram number 5
       CALL FFV1_0(W(1,14),W(1,12),W(1,9),GC_11,AMP(5))
-      CALL FFV2_1(W(1,7),W(1,6),GC_124,DCMPLX(CMASS_MDL_MT),W(1,16))
+      CALL FFV2_1(W(1,7),W(1,6),1.0D-05*GC_124,DCMPLX(173.3,-0.6836),
+     $   W(1,16))
 C     Amplitude(s) for diagram number 6
       CALL FFV1_0(W(1,5),W(1,16),W(1,15),GC_11,AMP(6))
 C     Amplitude(s) for diagram number 7"


for FIXEDSCALE in False True ; do
for ORDER in NLO LO ; do

### generate and apply patch
echo "set auto_convert_model T          # convert model to python3 automatically
import model ${MODEL}
set complex_mass_scheme True            # not actually needed if resonance width hardcoded
generate p p > t t~ t~ W+ [QCD]
output ${OUTDIR}
y# just in case some installation or overwritting is needed
" > ${OUTDIR}.cmd
if [[ ! -d "${OUTDIR}" ]] ; then
	date
	echo "--- Generate, output and patch"
	time $MG -f ${OUTDIR}.cmd
	time patch -p0 <<< "$PATCH"
fi


### launch
date
echo "launch ${OUTDIR}
fixed_order=OFF
shower=OFF
order=$ORDER
done
set aEWM1 1.289300e+02
set MZ 9.118800e+01
set MW 8.041900e+01
set MT 173.3
# set MB 4.7                             # invalid for 5FS
set ptj 10.
# set ptb 0.                             # no b cut options at NLO
set etaj -1.
# set etab -1.
# set drbj 0.                            # 0.7 corresponds to default jet radius at NLO
set pdlabel lhapdf
set lhaid 244600
set WW   0.  # 2.084650
set WT   0.  # 1.36728                   # anyway set to zero by MG as final state particle
set dynamical_scale_choice 3             # -1 and 3 are the same at MG5_aMC but not in MG5_LO
set fixed_ren_scale $FIXEDSCALE          # those two actually determine fixed vs dyn scale
set fixed_fac_scale $FIXEDSCALE          # those two actually determine fixed vs dyn scale
set mur_ref_fixed 600.3                  # 3*mt+mw = 3*173.3+80.419 = 600.3 GeV
set muf_ref_fixed 600.3
set mur_over_ref 1.0
set muf_over_ref 1.0
set rw_rscale 0.5,1.,2.
set rw_fscale 0.5,1.,2.
set reweight_scale True                  # reweight on the fly, but max 8 different scales
set reweight_PDF True
set store_rwgt_info True                 # needed for scale/pdf reweighting
# set use_syst True                      # doesn't exist at NLO, the following is enough:
set systematics_program systematics
set systematics_arguments ['--mur=0.125,0.149,0.177,0.21,0.25,0.297,0.354,0.42,0.5,0.595,0.707,0.841,1,1.19,1.41,1.68,2,2.38,2.83,3.36,4,4.76,5.66,6.73,8', '--muf=0.125,0.149,0.177,0.21,0.25,0.297,0.354,0.42,0.5,0.595,0.707,0.841,1,1.19,1.41,1.68,2,2.38,2.83,3.36,4,4.76,5.66,6.73,8', '--pdf=errorset', '--together=mur,muf', '--dyn=-1']
0" > ${OUTDIR}.cmd
time $MG -f ${OUTDIR}.cmd

date

done
done

### results should be the following:
## NLO, HT/2
#   --------------------------------------------------------------
#      Summary:
#      Process p p > t t~ t~ W+ [QCD]
#      Run at p-p collider (6500.0 + 6500.0 GeV)
#      Number of events generated: 10000
#      Total cross section: 5.203e-04 +- 1.5e-06 pb
#   --------------------------------------------------------------
#      Scale variation (computed from LHE events):
#          Dynamical_scale_choice 3 (envelope of 9 values): 
#              5.219e-04 pb  +15.4% -14.6%
#      PDF variation (computed from LHE events):
#          NNPDF23_nlo_as_0118_qed (101 members; using replicas method): 
#              5.223e-04 pb  +10.2% -10.2%
#   --------------------------------------------------------------
## LO, HT/2
#   --------------------------------------------------------------
#      Summary:
#      Process p p > t t~ t~ W+ [QCD]
#      Run at p-p collider (6500.0 + 6500.0 GeV)
#      Number of events generated: 10000
#      Total cross section: 2.913e-04 +- 6.0e-07 pb
#   --------------------------------------------------------------
#      Scale variation (computed from LHE events):
#          Dynamical_scale_choice 3 (envelope of 9 values): 
#              2.913e-04 pb  +33.1% -24.1%
#      PDF variation (computed from LHE events):
#          NNPDF23_nlo_as_0118_qed (101 members; using replicas method): 
#              2.915e-04 pb  +7.6% -7.6%
#   --------------------------------------------------------------
## NLO, 3mt+mw
#   --------------------------------------------------------------
#      Summary:
#      Process p p > t t~ t~ W+ [QCD]
#      Run at p-p collider (6500.0 + 6500.0 GeV)
#      Number of events generated: 10000
#      Total cross section: 5.232e-04 +- 1.5e-06 pb
#   --------------------------------------------------------------
#      Scale variation (computed from LHE events):
#          Dynamical_scale_choice 0 (envelope of 9 values): 
#              5.081e-04 pb  +17.3% -15.5%
#      PDF variation (computed from LHE events):
#          NNPDF23_nlo_as_0118_qed (101 members; using replicas method): 
#              5.086e-04 pb  +7.9% -7.9%
#   --------------------------------------------------------------
## LO, 3mt+mw
#   --------------------------------------------------------------
#      Summary:
#      Process p p > t t~ t~ W+ [QCD]
#      Run at p-p collider (6500.0 + 6500.0 GeV)
#      Number of events generated: 10000
#      Total cross section: 2.724e-04 +- 5.6e-07 pb
#   --------------------------------------------------------------
#      Scale variation (computed from LHE events):
#          Dynamical_scale_choice 0 (envelope of 9 values): 
#              2.725e-04 pb  +33.1% -24.0%
#      PDF variation (computed from LHE events):
#          NNPDF23_nlo_as_0118_qed (101 members; using replicas method): 
#              2.728e-04 pb  +7.7% -7.7%
#   --------------------------------------------------------------

