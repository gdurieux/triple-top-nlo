# Three-top-quark production at NLO

Reference inclusive rates and script computing three-top-quark production in association with a W or jet (denoted tttw and tttj below) at NLO with MG5_aMC, following:

> "The inseparable three and four tops"
> Gauthier Durieux, Hesham El Faham, Rikkert Frederix, Davide Pagani, Marco Zaro
> https://arxiv.org/abs/2607.27323

The DRW40 prescription is adopted to handle the overlap between tttw and four-top production in the five flavour scheme. The provided reference rates do include the qq>tttwb channel outside of the on-shell window.

The resulting tttw predictions should be combined with a four-top prediction where the invariant masses of all Wb pairs arising from top decays are restricted to a ±40 GeV window around the top mass to produce a consistent joint tttt+tttw prediction.

The first three leading orders are provided together with the first next-to-leading order (denoted LO + NLO1), which was shown to be a good approximation for the complete NLO prediction, both inclusively and differentially.

Because MadSTR is currently unable to handle tttj production, its overlap with tttw production is removed with a DR1 prescription implemented manually.

The input parameters and choices of PDFs have been agreed upon with ATLAS and CMS representatives under the umbrella of the LHC TOP WG:

- mt = 172.5 GeV, mW = 80.379 GeV, mZ = 91.1876 GeV, mH = 125 GeV, GF = 1.166636e-5 GeV
- PDF4LHC21_40_pdfas (93300) with aS = 0.118 as reference PDF for both LO and NLO contributions, and comparison with:

	- NNPDF31_nlo_as_0118_luxqed (324900) used by ATLAS
	- NNPDF31_nnlo_as_0118_mc_hessian_pdfas (325300) used by CMS
	- NNPDF40_nlo_as_01180_qed (335900) newer
	

Central scales are set to HT/4 and scale uncertainties are obtained from a seven-point variation.

The rates for `tbar t tbar W+` and `t tbar t W-` are identical so only the former is provided (denoted tttwp). The rates for `tbar t tbar j` and `t tbar t j` (denoted tttjp and tttjm) differ and are provided separately. Since we work in the five-flavour scheme, the `j` jet is possibly b-flavoured.

At 13 TeV:
```
tttwp, 13 TeV, LO + NLO1 DRW40        	   +15%   -14% (scales)		 (± 0.6% stat)
PDF4LHC21_40_pdfas                   	 0.863 fb	 ±7.0% (pdf)    -2.5%  +6.1% (aS)   -7.5% +9.3% (pdf+aS)
NNPDF31_nlo_as_0118_luxqed           	 0.756 fb	 ±3.3% (pdf)
NNPDF31_nnlo_as_0118_mc_hessian_pdfas	 0.760 fb	 ±3.1% (pdf)    -5.9%  +6.9% (aS)   -6.7% +7.6% (pdf+aS)
NNPDF40_nlo_as_01180_qed             	 0.683 fb	 ±2.4% (pdf)

tttjm, 13 TeV, LO + NLO1 DR1         	   +13%  -9.8% (scales)		 (± 0.4% stat)
PDF4LHC21_40_pdfas                   	 0.547 fb	 ±2.3% (pdf)   -0.71%  +3.4% (aS)   -2.4% +4.1% (pdf+aS)
NNPDF31_nlo_as_0118_luxqed           	 0.523 fb	 ±1.2% (pdf)
NNPDF31_nnlo_as_0118_mc_hessian_pdfas	 0.538 fb	 ±1.4% (pdf)      -4%  +3.5% (aS)   -4.3% +3.8% (pdf+aS)
NNPDF40_nlo_as_01180_qed             	 0.527 fb	 ±0.86% (pdf)

tttjp, 13 TeV, LO + NLO1 DR1         	   +15%   -10% (scales)		 (± 0.5% stat)
PDF4LHC21_40_pdfas                   	 0.232 fb	 ±4.7% (pdf)    -0.6%  +3.8% (aS)   -4.7% +6.0% (pdf+aS)
NNPDF31_nlo_as_0118_luxqed           	 0.215 fb	 ±2.3% (pdf)
NNPDF31_nnlo_as_0118_mc_hessian_pdfas	 0.224 fb	 ±3.7% (pdf)    -4.8%  +3.2% (aS)   -6.0% +4.9% (pdf+aS)
NNPDF40_nlo_as_01180_qed             	 0.219 fb	 ±1.3% (pdf)

```


At 13.6 TeV:
```
tttwp, 13.6 TeV, LO + NLO1 DRW40      	   +15%   -13% (scales)		 (± 0.5% stat)
PDF4LHC21_40_pdfas                   	  1.02 fb	 ±6.8% (pdf)    -2.4%    +6% (aS)   -7.2% +9.0% (pdf+aS)
NNPDF31_nlo_as_0118_luxqed           	 0.897 fb	 ±3.1% (pdf)
NNPDF31_nnlo_as_0118_mc_hessian_pdfas	 0.902 fb	 ±3.0% (pdf)    -5.9%  +6.9% (aS)   -6.6% +7.5% (pdf+aS)
NNPDF40_nlo_as_01180_qed             	 0.810 fb	 ±2.3% (pdf)

tttjm, 13.6 TeV, LO + NLO1 DR1       	   +14%  -9.8% (scales)		 (± 0.6% stat)
PDF4LHC21_40_pdfas                   	 0.623 fb	 ±2.2% (pdf)   -0.67%  +3.4% (aS)   -2.3% +4.0% (pdf+aS)
NNPDF31_nlo_as_0118_luxqed           	 0.597 fb	 ±1.1% (pdf)
NNPDF31_nnlo_as_0118_mc_hessian_pdfas	 0.613 fb	 ±1.4% (pdf)      -4%  +3.5% (aS)   -4.3% +3.8% (pdf+aS)
NNPDF40_nlo_as_01180_qed             	 0.601 fb	 ±0.83% (pdf)

tttjp, 13.6 TeV, LO + NLO1 DR1       	   +15%   -10% (scales)		 (± 0.6% stat)
PDF4LHC21_40_pdfas                   	 0.269 fb	 ±4.6% (pdf)   -0.59%  +3.8% (aS)   -4.7% +6.0% (pdf+aS)
NNPDF31_nlo_as_0118_luxqed           	 0.250 fb	 ±2.4% (pdf)
NNPDF31_nnlo_as_0118_mc_hessian_pdfas	 0.259 fb	 ±3.7% (pdf)    -4.8%  +3.1% (aS)   -6.1% +4.9% (pdf+aS)
NNPDF40_nlo_as_01180_qed             	 0.255 fb	 ±1.3% (pdf)
```


At 14 TeV:
```
tttwp, 14 TeV, LO + NLO1 DRW40        	   +15%   -13% (scales)		 (± 0.6% stat)
PDF4LHC21_40_pdfas                   	  1.15 fb	 ±6.6% (pdf)    -2.4%  +5.9% (aS)   -7.0% +8.9% (pdf+aS)
NNPDF31_nlo_as_0118_luxqed           	  1.02 fb	 ±3.1% (pdf)
NNPDF31_nnlo_as_0118_mc_hessian_pdfas	  1.02 fb	 ±3.0% (pdf)    -5.8%  +6.8% (aS)   -6.5% +7.4% (pdf+aS)
NNPDF40_nlo_as_01180_qed             	 0.920 fb	 ±2.2% (pdf)

tttjm, 14 TeV, LO + NLO1 DR1         	   +14%   -10% (scales)		 (± 0.5% stat)
PDF4LHC21_40_pdfas                   	 0.680 fb	 ±2.2% (pdf)    -0.7%  +3.4% (aS)   -2.3% +4.1% (pdf+aS)
NNPDF31_nlo_as_0118_luxqed           	 0.651 fb	 ±1.1% (pdf)
NNPDF31_nnlo_as_0118_mc_hessian_pdfas	 0.669 fb	 ±1.4% (pdf)    -4.1%  +3.5% (aS)   -4.3% +3.8% (pdf+aS)
NNPDF40_nlo_as_01180_qed             	 0.656 fb	 ±0.82% (pdf)

tttjp, 14 TeV, LO + NLO1 DR1         	   +15%   -10% (scales)		 (± 0.8% stat)
PDF4LHC21_40_pdfas                   	 0.298 fb	 ±4.6% (pdf)    -0.6%  +3.8% (aS)   -4.7% +6.0% (pdf+aS)
NNPDF31_nlo_as_0118_luxqed           	 0.276 fb	 ±2.4% (pdf)
NNPDF31_nnlo_as_0118_mc_hessian_pdfas	 0.287 fb	 ±3.9% (pdf)    -4.8%  +3.1% (aS)   -6.2% +5.0% (pdf+aS)
NNPDF40_nlo_as_01180_qed             	 0.282 fb	 ±1.2% (pdf)
```

