#!/bin/bash -e 

## Adapted from cellgeni script to work with ancestry annotation pipeline

## v3.1 of STARsolo wrappers is set up to guess the chemistry automatically
## newest version of the script uses STAR v2.7.10a with EM multimapper processing (not possible for all platforms) 


FQDIR=$1
SAMP=$2
REF=$3
CPUS=$4
OUT=$5
STAR=$6
SAMTOOLS=$7

if [[ $FQDIR == "" || $SAMP == "" || $REF == "" || $CPUS == "" || $OUT == "" || $STAR == "" || $SAMTOOLS == "" ]]
then
  >&2 echo "Usage: ./starsolo_dropseq.sh  <fastq_dir> <sample_id> <star_mapping_reference> <cpus> <out_dir> <STAR_path> <samtools_path>"
  >&2 echo "typically run with qsub on short.q with 16 cores and 4G RAM per thread"
  exit 1
fi



###################################################################### DONT CHANGE OPTIONS BELOW THIS LINE ##############################################################################################
echo "Making output direcotry and changing location there"
mkdir $OUT && cd $OUT

## three popular cases: <sample>_1.fastq/<sample>_2.fastq, <sample>.R1.fastq/<sample>.R2.fastq, and <sample>_L001_R1_S001.fastq/<sample>_L001_R2_S001.fastq
# "fastq.gz", "fastq", "fq.gz", "fq"
## the command below will generate a comma-separated list for each read
R1=""
R2=""
if [[ `find $FQDIR/* | grep $SAMP | grep "_1\.fastq" | grep -v ".txt" | grep -v ".sha256"` != "" ]] ## This will work for both _1.fastq and _1.fastq.gz
then 
  R1=`find $FQDIR/* | grep $SAMP | grep "_1\.fastq" | grep -v ".txt" | grep -v ".sha256" | sort | tr '\n' ',' | sed "s/,$//g"`
  R2=`find $FQDIR/* | grep $SAMP | grep "_2\.fastq" | grep -v ".txt" | grep -v ".sha256" | sort | tr '\n' ',' | sed "s/,$//g"`
elif [[ `find $FQDIR/* | grep $SAMP | grep "R1\.fastq" | grep -v ".txt" | grep -v ".sha256"` != "" ]] ## This will work for both R1.fastq and R1.fastq.gz
then
  R1=`find $FQDIR/* | grep $SAMP | grep "R1\.fastq" | grep -v ".txt" | grep -v ".sha256" | sort | tr '\n' ',' | sed "s/,$//g"`
  R2=`find $FQDIR/* | grep $SAMP | grep "R2\.fastq" | grep -v ".txt" | grep -v ".sha256" | sort | tr '\n' ',' | sed "s/,$//g"`
elif [[ `find $FQDIR/* | grep $SAMP | grep "_R1_.*\.fastq" | grep -v ".txt" | grep -v ".sha256"` != "" ]]  ## This will work for both R1_*.fastq and R1*.fastq.gz
then
  R1=`find $FQDIR/* | grep $SAMP | grep "_R1_" | grep -v ".txt" | grep -v ".sha256" | sort | tr '\n' ',' | sed "s/,$//g"`
  R2=`find $FQDIR/* | grep $SAMP | grep "_R2_" | grep -v ".txt" | grep -v ".sha256" | sort | tr '\n' ',' | sed "s/,$//g"`
elif [[ `find $FQDIR/* | grep $SAMP | grep "_1\.fq" |  grep -v ".txt" | grep -v ".sha256"` != "" ]] ## This will work for both _1.fq and _1.fq.gz
then 
  R1=`find $FQDIR/* | grep $SAMP | grep "_1\.fq" | grep -v ".txt" | grep -v ".sha256" | sort | tr '\n' ',' | sed "s/,$//g"`
  R2=`find $FQDIR/* | grep $SAMP | grep "_2\.fq" | grep -v ".txt" | grep -v ".sha256" | sort | tr '\n' ',' | sed "s/,$//g"`
elif [[ `find $FQDIR/* | grep $SAMP | grep "R1\.fq" | grep -v ".txt" | grep -v ".sha256"` != "" ]] ## This will work for both R1.fq and R1.fq.gz
then
  R1=`find $FQDIR/* | grep $SAMP | grep "R1\.fq" | grep -v ".txt" | grep -v ".sha256" | sort | tr '\n' ',' | sed "s/,$//g"`
  R2=`find $FQDIR/* | grep $SAMP | grep "R2\.fq" | grep -v ".txt" | grep -v ".sha256" | sort | tr '\n' ',' | sed "s/,$//g"`
elif [[ `find $FQDIR/* | grep $SAMP | grep "_R1_.*\.fq" | grep -v ".txt" | grep -v ".sha256"` != "" ]] ## This will work for both R1_*.fq and R1_*.fq.gz
then
  R1=`find $FQDIR/* | grep $SAMP | grep "_R1_" | grep -v ".txt" | grep -v ".sha256" | sort | tr '\n' ',' | sed "s/,$//g"`
  R2=`find $FQDIR/* | grep $SAMP | grep "_R2_" | grep -v ".txt" | grep -v ".sha256" | sort | tr '\n' ',' | sed "s/,$//g"`
else 
  >&2 echo "ERROR: No appropriate fastq files were found! Please check file formatting, and check if you have set the right FQDIR."
  exit 1
fi 


## let's see if the files are archived or not. Gzip is the only one we test for, but bgzip archives should work too since they are gzip-compatible.
GZIP=""
if [[ `find $FQDIR/* | grep $SAMP | grep "\.gz$"` != "" ]]
then  
  GZIP="--readFilesCommand zcat"
fi


echo "Done setting up the STARsolo run; here are final processing options:"
echo "============================================================================="
echo "Sample: $SAMP"
echo "Paired-end mode: False"
echo "Strand: Forward"
echo "CB length: 12"
echo "UMI length: 8"
echo "GZIP: $GZIP"
echo "-----------------------------------------------------------------------------"
echo "Read 1 files: $R1"
echo "-----------------------------------------------------------------------------"
echo "Read 2 files: $R2" 
echo "-----------------------------------------------------------------------------"


## choose one of the two otions, depending on whether you need a BAM file 
BAM="--outSAMtype BAM SortedByCoordinate --outBAMsortingBinsN 500 --limitBAMsortRAM 60000000000 --outMultimapperOrder Random --runRNGseed 1 --outSAMattributes NH HI AS nM CB UB CR CY UR UY GX GN"


$STAR --runThreadN $CPUS --genomeDir $REF --readFilesIn $R2 $R1 --runDirPerm All_RWX $GZIP $BAM \
     --soloType CB_UMI_Simple --soloCBwhitelist None --soloCBstart 1 --soloCBlen 12 --soloUMIstart 13 --soloUMIlen 8 --soloBarcodeReadLength 0 \
     --soloFeatures GeneFull --soloOutFileNames out/ features.tsv barcodes.tsv matrix.mtx


## check mapping rate
UNIQFRQ=`grep "Reads Mapped to Genome: Unique," $OUT/outs/GeneFull/Summary.csv | awk -F "," '{print $2}'`
GENEPCT=`grep "Reads Mapped to GeneFull: Unique GeneFull" $OUT/outs/GeneFull/Summary.csv | awk -F "," -v v=$UNIQFRQ '{printf "%d\n",$2*100/v}'`

## report any low amoutns of mapping
if (( $GENEPCT < 35 )) 
then
  >&2 echo "ERROR: The percent mapping is too low ($GENEPCT). The data may not be the direction you thought ($PRIME\prime). Deleting results."
fi


## index the BAM file
if [[ -s $OUT/Aligned.sortedByCoord.out.bam ]]
then
  $SAMTOOLS index -@16 $OUT/Aligned.sortedByCoord.out.bam
fi


## finally, let's gzip all outputs
gzip $OUT/Unmapped.out.mate1
gzip $OUT/Unmapped.out.mate2

gzip $OUT/outs/GeneFull/filtered/matrix.mtx
gzip $OUT/outs/GeneFull/filtered/barcodes.tsv
gzip $OUT/outs/GeneFull/filtered/features.tsv

gzip $OUT/outs/GeneFull/raw/matrix.mtx
gzip $OUT/outs/GeneFull/raw/barcodes.tsv
gzip $OUT/outs/GeneFull/raw/features.tsv


## remove test files 
rm -rf $OUT/test.R?.fastq
rm -rf $OUT/_STARtmp

# ## finally, let's gzip all outputs
# cd output
# for i in Gene/raw Gene/filtered GeneFull/raw GeneFull/filtered
# do 
#   cd $i; for j in *; do gzip $j & done
#   cd ../../
# done

wait
echo "ALL DONE!"