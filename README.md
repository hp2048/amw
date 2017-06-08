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
 do dataid=`echo $f | sed -r 's/\/short\/te53\/minionseq\///' | sed -r 's/\//_/g' | sed -r 's/.tar.gz//'`; qsub -v dataid=$dataid,reference=/short/te53/reference/blastn/Homo_sapiens.GRCh38.dna.primary_assembly.fa,inputfile=$f,outputdir=/short/te53/analysis/20170309 /short/te53/ncig/run_albacore_poretools_blastn.sh; break; done
```

#### NOTES:
1. Change parameters of job submission as required. i.e. Project ID, walltime, etc.