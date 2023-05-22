#!/bin/bash -e 

## Adapted from cellgeni script to work with ancestry annotation pipeline

## v3.1 of STARsolo wrappers is set up to guess the chemistry automatically
## newest version of the script uses STAR v2.7.10a with EM multimapper processing 
## in STARsolo which on by default; the extra matrix can be found in /raw subdir 


FQDIR=$1
SAMP=$2
REF=$3
WL_DIR=$4
PRIME=$5
CPUS=$6
OUT=$7
STAR=$8
SEQTK=$9
SAMTOOLS=${10}

if [[ $FQDIR == "" || $SAMP == "" || $REF == "" || $WL_DIR == "" || $PRIME == "" || $CPUS == "" || $OUT == "" || $STAR == "" || $SEQTK == "" || $SAMTOOLS == "" ]]
then
  >&2 echo "Usage: ./starsolo_10x.sh <fastq_dir> <sample_id> <star_mapping_reference> <whitelist_dir> <3_or_5_prime> <cpus> <out_dir> <STAR_path> <SEQTK_path> <samtools_path>"
  >&2 echo "Will try to automatically detect the 10x chemistry"
  >&2 echo "3_or_5_prime is either 3 or 5 depending on if the chemistry is 3' or 5'"
  >&2 echo "typically run with qsub on short.q with 16 cores and 4G RAM per thread"
  exit 1
fi



###################################################################### DONT CHANGE OPTIONS BELOW THIS LINE 
##############################################################################################

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
elif [[ `find $FQDIR/* | grep $SAMP | grep "R1\.fastq"` != "" ]] ## This will work for both R1.fastq and R1.fastq.gz
then
  R1=`find $FQDIR/* | grep $SAMP | grep "R1\.fastq" | grep -v ".txt" | grep -v ".sha256" | sort | tr '\n' ',' | sed "s/,$//g"`
  R2=`find $FQDIR/* | grep $SAMP | grep "R2\.fastq" | grep -v ".txt" | grep -v ".sha256" | sort | tr '\n' ',' | sed "s/,$//g"`
elif [[ `find $FQDIR/* | grep $SAMP | grep "_R1_.*\.fastq"` != "" ]]  ## This will work for both R1_*.fastq and R1*.fastq.gz
then
  R1=`find $FQDIR/* | grep $SAMP | grep "_R1_" | grep -v ".txt" | grep -v ".sha256" | sort | tr '\n' ',' | sed "s/,$//g"`
  R2=`find $FQDIR/* | grep $SAMP | grep "_R2_" | grep -v ".txt" | grep -v ".sha256" | sort | tr '\n' ',' | sed "s/,$//g"`
elif [[ `find $FQDIR/* | grep $SAMP | grep "_1\.fq" |  grep -v ".txt"` != "" ]] ## This will work for both _1.fq and _1.fq.gz
then 
  R1=`find $FQDIR/* | grep $SAMP | grep "_1\.fq" | grep -v ".txt" | grep -v ".sha256" | sort | tr '\n' ',' | sed "s/,$//g"`
  R2=`find $FQDIR/* | grep $SAMP | grep "_2\.fq" | grep -v ".txt" | grep -v ".sha256" | sort | tr '\n' ',' | sed "s/,$//g"`
elif [[ `find $FQDIR/* | grep $SAMP | grep "R1\.fq" | grep -v ".txt"` != "" ]] ## This will work for both R1.fq and R1.fq.gz
then
  R1=`find $FQDIR/* | grep $SAMP | grep "R1\.fq" | grep -v ".txt" | grep -v ".sha256" | sort | tr '\n' ',' | sed "s/,$//g"`
  R2=`find $FQDIR/* | grep $SAMP | grep "R2\.fq" | grep -v ".txt" | grep -v ".sha256" | sort | tr '\n' ',' | sed "s/,$//g"`
elif [[ `find $FQDIR/* | grep $SAMP | grep "_R1_.*\.fq" | grep -v ".txt"` != "" ]] ## This will work for both R1_*.fq and R1_*.fq.gz
then
  R1=`find $FQDIR/* | grep $SAMP | grep "_R1_" | grep -v ".txt" | grep -v ".sha256" | sort | tr '\n' ',' | sed "s/,$//g"`
  R2=`find $FQDIR/* | grep $SAMP | grep "_R2_" | grep -v ".txt" | grep -v ".sha256" | sort | tr '\n' ',' | sed "s/,$//g"`
else 
  >&2 echo "ERROR: No appropriate fastq files were found! Please check file formatting, and check if you have set the right FQDIR."
  exit 1
fi 


echo $R1
echo $R2

## also define one file from R1/R2; we choose the largest one, because sometimes there are tiny files from trial runs
R1F=`echo $R1 | tr ',' ' ' | xargs ls -s | tail -n1 | awk '{print $2}'`
R2F=`echo $R2 | tr ',' ' ' | xargs ls -s | tail -n1 | awk '{print $2}'`

## let's see if the files are archived or not. Gzip is the most common, but bgzip archives should work too since they are gzip-compatible.
GZIP=""
BC=""
NBC1=""
NBC2=""
NBC3=""
NBCA=""
R1LEN=""
R2LEN=""
R1DIS=""


## randomly subsample 200k reads - let's hope there are at least this many (there should be):
$SEQTK sample -s100 $R1F 200000 >$OUT/test.R1.fastq &
$SEQTK sample -s100 $R2F 200000 > $OUT//test.R2.fastq &
wait

## see if the original fastq files are zipped: 
if [[ `find $FQDIR/* | grep $SAMP | grep "\.gz$"` != "" ]]
then  
  GZIP="--readFilesCommand zcat"
fi

NBC1=`cat $OUT/test.R1.fastq | awk 'NR%4==2' | grep -F -f $WL_DIR/737K-april-2014_rc.txt | wc -l`
NBC2=`cat $OUT/test.R1.fastq | awk 'NR%4==2' | grep -F -f $WL_DIR/737K-august-2016.txt | wc -l`
NBC3=`cat $OUT/test.R1.fastq | awk 'NR%4==2' | grep -F -f $WL_DIR/3M-february-2018.txt | wc -l`
NBCA=`cat $OUT/test.R1.fastq | awk 'NR%4==2' | grep -F -f $WL_DIR/737K-arc-v1.txt | wc -l`
NBCF=`cat $OUT/test.R1.fastq | awk 'NR%4==2' | grep -F -f $WL_DIR/737K-fixed-rna-profiling.txt | wc -l`
R1LEN=`cat $OUT/test.R1.fastq | awk 'NR%4==2' | awk '{sum+=length($0)} END {printf "%d\n",sum/NR+0.5}'`
R2LEN=`cat $OUT/test.R2.fastq | awk 'NR%4==2' | awk '{sum+=length($0)} END {printf "%d\n",sum/NR+0.5}'`
R1DIS=`cat $OUT/test.R1.fastq | awk 'NR%4==2' | awk '{print length($0)}' | sort | uniq -c | wc -l`


echo $NBC1 
echo $NBC2 
echo $NBC3 
echo $NBCA

## elucidate the right barcode whitelist to use. Grepping out N saves us some trouble. Note the special list for multiome experiments (737K-arc-v1.txt):
## 80k (out of 200,000) is an empirical number - I've seen <50% barcodes matched to the whitelist, but a number that's < 40% suggests something is very wrong
if (( $NBC3 > 80000 )) 
then 
  BC=$WL_DIR/3M-february-2018.txt
elif (( $NBC2 > 80000 ))
then
  BC=$WL_DIR/737K-august-2016.txt
elif (( $NBCA > 80000 ))
then
  BC=$WL_DIR/737K-arc-v1.txt
elif (( $NBC1 > 80000 )) 
then
  BC=$WL_DIR/737K-april-2014_rc.txt
elif (( $R1LEN > 80000 ))
then
  BC=$WL_DIR/737K-fixed-rna-profiling.txt
else 
  >&2 echo "ERROR: No whitelist has matched a random selection of 200,000 barcodes! Match counts: $NBC1 (v1), $NBC2 (v2), $NBC3 (v3), $NBCA (multiome)."
  exit 1
fi 

## check read lengths, fail if something funky is going on: 
PAIRED=False
UMILEN=""
CBLEN=""
if (( $R1DIS > 1 && $R1LEN <= 30 ))
then 
  >&2 echo "ERROR: Read 1 (barcode) has varying length; possibly someone thought it's a good idea to quality-trim it. Please check the fastq files."
  exit 1
elif (( $R1LEN < 24 )) 
then
  >&2 echo "ERROR: Read 1 (barcode) is less than 24 bp in length. Please check the fastq files."
  exit 1
elif (( $R2LEN < 40 )) 
then
  >&2 echo "ERROR: Read 2 (biological read) is less than 40 bp in length. Please check the fastq files."
  exit 1
fi

## assign the necessary variables for barcode/UMI length/paired-end processing. 
## scripts was changed to not rely on read length for the UMIs because of the epic Hassan case
# (v2 16bp barcodes + 10bp UMIs were sequenced to 28bp, effectively removing the effects of the UMIs)
if (( $R1LEN > 50 )) 
then
  PAIRED=True
fi

if [[ $BC == "$WL_DIR/3M-february-2018.txt" || $BC == "$WL_DIR/737K-arc-v1.txt" ]] 
then 
  CBLEN=16
  UMILEN=12
elif [[ $BC == "$WL_DIR/737K-august-2016.txt" ]] 
then
  CBLEN=16
  UMILEN=10
elif [[ $BC == "$WL_DIR/737K-april-2014_rc.txt" ]] 
then
  CBLEN=14
  UMILEN=10
fi 

## finally, see if you have 5' or 3' experiment. I don't know and easier way than to run a test alignment:  
if (( $PRIME==3 )) 
then
    STRAND=Forward
elif (( $PRIME==5 )) 
then
  STRAND=Reverse
fi

## finally, if paired-end experiment turned out to be 3' (yes, they do exist!), process it as single-end: 
if [[ $STRAND == "Forward" && $PAIRED == "True" ]]
then
  PAIRED=False
fi

echo "Done setting up the STARsolo run; here are final processing options:"
echo "============================================================================="
echo "Sample: $SAMP"
echo "Paired-end mode: $PAIRED"
echo "Strand (Forward = 3', Reverse = 5'): $STRAND"
echo "CB whitelist: $BC, matches out of 200,000: $NBC3 (v3), $NBC2 (v2), $NBC1 (v1), $NBCA (multiome) "
echo "CB length: $CBLEN"
echo "UMI length: $UMILEN"
echo "GZIP: $GZIP"
echo "-----------------------------------------------------------------------------"
echo "Read 1 files: $R1"
echo "-----------------------------------------------------------------------------"
echo "Read 2 files: $R2" 
echo "-----------------------------------------------------------------------------"


### Set bam to output since can't run ancestry annotation otherwise!
BAM="--outSAMtype BAM SortedByCoordinate --outBAMsortingBinsN 500 --limitBAMsortRAM 960000000000 --outMultimapperOrder Random --runRNGseed 1 --outSAMattributes NH HI AS nM CB UB CR CY UR UY GX GN"

cd $OUT

if [[ $PAIRED == "True" ]]
then
  ## note the R1/R2 order of input fastq reads and --soloStrand Forward for 5' paired-end experiment
  $STAR --runThreadN $CPUS --genomeDir $REF --readFilesIn $R1 $R2 --runDirPerm All_RWX $GZIP $BAM --soloBarcodeMate 1 --clip5pNbases 39 0 \
     --soloType CB_UMI_Simple --soloCBwhitelist $BC --soloCBstart 1 --soloCBlen $CBLEN --soloUMIstart $((CBLEN+1)) --soloUMIlen $UMILEN --soloStrand Forward \
     --soloUMIdedup 1MM_CR --soloCBmatchWLtype 1MM_multi_Nbase_pseudocounts --soloUMIfiltering MultiGeneUMI_CR \
     --soloCellFilter EmptyDrops_CR --outFilterScoreMin 30 \
     --soloFeatures GeneFull --soloOutFileNames outs/ features.tsv barcodes.tsv matrix.mtx --soloMultiMappers EM --outReadsUnmapped Fastx
else 
  $STAR --runThreadN $CPUS --genomeDir $REF --readFilesIn $R2 $R1 --runDirPerm All_RWX $GZIP $BAM \
     --soloType CB_UMI_Simple --soloCBwhitelist $BC --soloBarcodeReadLength 0 --soloCBlen $CBLEN --soloUMIstart $((CBLEN+1)) --soloUMIlen $UMILEN --soloStrand $STRAND \
     --soloUMIdedup 1MM_CR --soloCBmatchWLtype 1MM_multi_Nbase_pseudocounts --soloUMIfiltering MultiGeneUMI_CR \
     --soloCellFilter EmptyDrops_CR --clipAdapterType CellRanger4 --outFilterScoreMin 30 \
     --soloFeatures GeneFull --soloOutFileNames outs/ features.tsv barcodes.tsv matrix.mtx --soloMultiMappers EM --outReadsUnmapped Fastx
fi


## the following is needed in case of bad samples: when a low fraction of reads come from mRNA, experiment will look falsely reverse-stranded
UNIQFRQ=`grep "Reads Mapped to Genome: Unique," $OUT/outs/GeneFull/Summary.csv | awk -F "," '{print $2}'`
GENEPCT=`grep "Reads Mapped to GeneFull: Unique GeneFull" $OUT/outs/GeneFull/Summary.csv | awk -F "," -v v=$UNIQFRQ '{printf "%d\n",$2*100/v}'`

## this percentage is very empirical, but was found to work in 99% of cases. 
## any 10x 3' run with GENEPCT < 35%, and any 5' run with GENEPCT > 35% are 
## *extremely* strange and need to be carefully evaluated
if (( $GENEPCT < 35 )) 
then
  >&2 echo "ERROR: The percent mapping is too low ($GENEPCT). The data may not be the direction you thought ($PRIME\prime). Deleting results."
  rm -rf $OUT
  exit 1
fi


## index the BAM file
if [[ -s $OUT/Aligned.sortedByCoord.out.bam ]]
then
  echo "indexing bam"
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

# cd $OUT
# for i in $OUT/GeneFull/raw $OUT/GeneFull/filtered 
# do 
#   cd $i; for j in *; do gzip $j & done
#   cd ../../
# done

wait
echo "ALL DONE!"
