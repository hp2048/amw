This repository along with Wiki pages contains information, scripts, discussion regarding the processing of MinION datasets using Raijin resources.

Run the albacore on a tar.gz file as follows:

```
qsub -P te53 \
-o $HOME/testalbacore/ \
-v dataid=testdata,inputfile=$HOME/miniontest.tar.gz,outputdir=$HOME/testalbacore,flowcell=FLO-MIN106,libkit=SQK-LSK108,configfile=r94_450bps_linear.cfg \
-q express \
-l walltime=00:10:00 \
-l mem=12000MB \
-l ncpus=16 \
-N albacore \
-j oe \
-l jobfs=100GB \
albacore_poretools.sh
```

####NOTES:
1. Change parameters of job submission as required. i.e. Project ID, walltime, etc.