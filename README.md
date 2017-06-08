This repository along with Wiki pages contains information, scripts, discussion regarding the processing of MinION datasets using Raijin resources.

The base command for running albacore on a tar.gz file is as follows:

```
qsub \
-P te53 \
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


For multiple tar.gz files:

```
for f in `find /path/for/fast5/tar.gz/ -name "*.tar.gz"`
 do 
 dataid=`md5sum miniontest.tar.gz | cut -f1 -d ' '`
 qsub \
 -P te53 \
 -o $HOME/testalbacore/ \
 -v dataid=$dataid,inputfile=$f,outputdir=$HOME/testalbacore,flowcell=FLO-MIN106,libkit=SQK-LSK108,configfile=r94_450bps_linear.cfg -q express \
 -l walltime=00:10:00 \
 -l mem=12000MB \
 -l ncpus=16 \
 -N albacore \
 -j oe \
 -l jobfs=100GB \
 albacore_poretools.sh

```

#### NOTES:
1. Change parameters of job submission as required. i.e. Project ID, walltime, etc.