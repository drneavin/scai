#!/bin/bash -e 

## Adapted from cellgeni script to work with ancestry annotation pipeline

## v3.1 of STARsolo wrappers is set up to guess the chemistry automatically
## newest version of the script uses STAR v2.7.10a with EM multimapper processing 
## in STARsolo which on by default; the extra matrix can be found in /raw subdir 


FQDIR=$1
SAMP=$2
REF=$3
WL_DIR=$4
CPUS=$5
OUT=$6
STAR=$7
SAMTOOLS=$8

if [[ $FQDIR == "" || $SAMP == "" || $REF == "" || $WL_DIR == "" || $CPUS == "" || $OUT == "" || $STAR == "" || $SAMTOOLS == "" ]]
then
  >&2 echo "Usage: ./starsolo_indrops.sh <fastq_dir> <sample_id> <star_mapping_reference> <whitelist_dir> <cpus> <out_dir> <STAR_path> <samtools_path>"
  >&2 echo ""
  exit 1
fi


ADAPTER=GAGTGATTGCTTGTGACGCCTT     ## these could be GAGTGATTGCTTGTGACGCCTT or GAGTGATTGCTTGTGACGCCAA 
BC1=$WL_DIR/indrop/gel_barcode1_list.txt
BC2=$WL_DIR/indrop/gel_barcode2_list.txt


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
echo "Adapter: $ADAPTER"
echo "-----------------------------------------------------------------------------"
echo "Read 1 files: $R1"
echo "-----------------------------------------------------------------------------"
echo "Read 2 files: $R2" 
echo "-----------------------------------------------------------------------------"



## choose one of the two otions, depending on whether you need a BAM file 
BAM="--outSAMtype BAM SortedByCoordinate --outBAMsortingBinsN 500 --limitBAMsortRAM 60000000000 --outMultimapperOrder Random --runRNGseed 1 --outSAMattributes NH HI AS nM CB UB CR CY UR UY GX GN"

## increased soloAdapterMismatchesNmax to 3, as per discussions in STAR issues
$STAR  --runThreadN $CPUS --genomeDir $REF --readFilesIn $R2 $R1 --runDirPerm All_RWX $GZIP $BAM \
     --soloType CB_UMI_Complex --soloCBwhitelist $BC1 $BC2 --soloAdapterSequence $ADAPTER  \
     --soloAdapterMismatchesNmax 3 --soloCBmatchWLtype 1MM --soloCBposition 0_0_2_-1 3_1_3_8 --soloUMIposition 3_9_3_14 \
     --soloFeatures GeneFull --soloOutFileNames outs/ features.tsv barcodes.tsv matrix.mtx


## index the BAM file
if [[ -s $OUT/Aligned.sortedByCoord.out.bam ]]
then
  $SAMTOOLS index -@16 $OUT/Aligned.sortedByCoord.out.bam &
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


# ## finally, let's gzip all outputs
# cd output
# for i in Gene/raw Gene/filtered GeneFull/raw GeneFull/filtered
# do 
#   cd $i; for j in *; do gzip $j & done
#   cd ../../
# done

wait
echo "ALL DONE!"