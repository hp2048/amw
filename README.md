This repository along with Wiki pages contains information, scripts, discussion regarding the processing of MinION datasets using Raijin resources.

Run the albacore and poretools on a tar.gz file as follows:

`qsub -P yourNCIprojectID -o /directory/path/for/stdout-err/files/ -v dataid=mytestdata,inputfile=testinputfile.tar.gz,outputdir=/path/to/output/directory albacore_poretools.sh`