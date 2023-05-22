#!/bin/bash -e 

## single cell admixture inference (scai) pipeline
## Used to infer ancestral admixture in single-cell data
## scai variants uses monopogen and vcf2beagle to call variants and convert them to a beagle format for ancestry admixture inference.


show_help() {
cat << EOF
Usage: ${0##*/} [-hv] -s SCAI_DIR -b BAM -c CHR -e BED -f FASTA -o OUT
scai: single cell admixture inference pipeline

Call genetic variants for a sample from a bam file and convert to a beagle format for admixture inference with scai_ancestry


    -h          Display this help and exit. 
    -s SCAI_DIR Path to scai directory. Required.
    -b BAM      Path for bam file to be processed. Required.
    -c CHR      Chromosome name to be processed. Required.
    -e BED      Genetic variant bed file. Required.
    -f FASTA    Path to fasta file to be used as reference for SNP calling. It is best if this is the same fasta used for read alignment. Required.
    -o OUT      Path to output directory to write all the files. If the file doesn't exist, it will be created. Required.
EOF
}


while getopts "hsbcefo:" opt; do
  case $opt in
    h) 
        show_help
        exit 0
        ;;
    s) SCAI="$OPTARG"
    ;;
    b) BAM="$OPTARG"
    ;;
    c) CHR="$OPTARG"
    ;;
    e) BED="$OPTARG"
    ;;
    f) FASTA="$OPTARG"
    ;;
    o) OUT="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    exit 1
    ;;
  esac

  case $OPTARG in
    -*) echo "Option $opt needs a valid argument"
    exit 1
    ;;
  esac
done

printf "Using scai directory: %s\n" "$SCAI"
printf "Calling variants for bam file: %s\n" "$BAM"
printf "Calling variants for chromosome: %s\n" "$CHR"
printf "Calling variants for locations in provided bed file: %s\n" "$BED"
printf "Using reference fasta: %s\n" "$FASTA"
printf "Will write results to directory: %s\n" "$OUT"



##### 1. Run updated version of monopogen which just runs the first couple steps (samtools snp calling and removal of indels/homozygous ref snps)
### if monopogen hasn't been run, run it
if [ ! -f ... ]
then
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$SCAI/apps/

    python $SCAI/scripts/Monopogen4ancestry_bed_locations.py SCvarCall \
        -b $BAM \
        -a $SCAI/apps/ \
        -c $CHR \
        -o $OUT \
        -r $FASTA \
        -d 100 \
        -t 0.1 \
        -m 3 \
        -s 1 \
        -e $BED
else
    echo "Looks like monopogen has already been run.\nIf you want to rerun this step, please remove the ... or move it elsewhere to force rerun"
fi


##### 1. Run updated version of monopogen which just runs the first couple steps (samtools snp calling and removal of indels/homozygous ref snps)
### if monopogen hasn't been run, run it
if [ ! -f ... ]
then
    perl /directflow/SCCGGroupShare/projects/DrewNeavin/software/vcf2beagle_edited.pl --in=$OUT/SCvarCall/$CHR.gl.vcf.gz --out=$OUT/$CHR.beagle.gl --PL
else
    echo "Looks like conversion of monopogen outputs to beagle files has already been run.\nIf you want to rerun this step, please remove the ... or move it elsewhere to force rerun"
fi

