#!/bin/bash -e 

## single cell admixture inference (scai) pipeline
## Used to infer ancestral admixture in single-cell data
## scai ancestry uses fastNGSadmix to estimate ancestral admixture.


show_help() {
cat << EOF
Usage: ${0##*/} [-hv] -d DIR -b BAM -c CHR -e BED -f FASTA -o OUT
scai: single cell admixture inference pipeline

Call genetic variants for a sample from a bam file and convert to a beagle format for admixture inference with scai_ancestry


    -h              Display this help and exit. 
    -s SCAI_DIR     Directory for scai toolset.
    -d DIR          Path to directory containing scai_variants results. This should be the same path used for OUTDIR for scari_variants. Required.
    -n FILE_NAME    Name of file to be written at DIR. The files that will be written will be DIR/FILENAME.qopt and DIR/FILENAME.log. Required.
    -f FREQ_FILE    The file containing the frequency for each population in the format required by fastNGSadmix. Files for different human genome versions are provided and can be downloaded on the scai documentation.
    -i N_IND_FILE   The number of individuals for each population included in the FREQ_FILE in the format required by fastNGSadmix. Files for different human genome versions can be downloaded on the scai documentation.
EOF
}


while getopts "hsdnfi:" opt; do
  case $opt in
    h) 
        show_help
        exit 0
        ;;
    s) SCAI_DIR="$OPTARG"
    ;;
    d) DIR="$OPTARG"
    ;;
    n) FILE_NAME="$OPTARG"
    ;;
    f) FREQ_FILE="$OPTARG"
    ;;
    i) N_IND_FILE="$OPTARG"
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
printf "Using directory: %s\n" "$DIR"
printf "Writing results with filename: %s\n" "$FILE_NAME"
printf "Using this frequency file: %s\n" "$FREQ_FILE"
printf "Using this file with the number of individuals for the frequency file: %s\n" "$N_IND_FILE"





##### 3. Merge the different beagle files together and gzip
### if beagle merging hasn't been run, then run it
if [ ! -f $DIR/beagle/beagle.gl.gz ]
then
    head_file=`ls $DIR/beagle/*.beagle.gl | cut -d' ' -f1 | head -n 1`
    head -n 1 $head_file > $DIR/beagle/beagle.gl.gz
    tail -n +2 $DIR/beagle/*.beagle.gl >> $DIR/beagle/beagle.gl.gz
    sed -i '/^$/d' $DIR/beagle/beagle.gl.gz
    sed -i '/==>/d' $DIR/beagle/beagle.gl.gz
    sed -i '/ N /d' $DIR/beagle/beagle.gl.gz
    sed -i 's/:[ACTG]:[ACTG] / /g' $DIR/beagle/beagle.gl.gz
    sed -i 's/:/_/g' $DIR/beagle/beagle.gl.gz
    sed -i 's/ /\\t/g' $DIR/beagle/beagle.gl.gz
    sed -i 's/^chr//g' $DIR/beagle/beagle.gl.gz
    gzip $DIR/beagle/beagle.gl.gz
else
    echo "Looks like the beagle files have already been merged.\nIf you want to rerun this step, please remove the file beagle.gl.gz or move it elsewhere to force rerun"
fi


##### =3. Run fastNGSadmix
if [ ! -f $DIR/$FILE_NAME ]
then
    $SCAI_DIR/apps/fastNGSadmix -likes $DIR/beagle/beagle.gl.gz -fname $FREQ_FILE -Nname $N_IND_FILE -out $DIR/$FILE_NAME -whichPops 'all'
else
    echo "Looks like fastNGSadmix has already been written to this file name .\nIf you want to rerun this step, please remove the file beagle.gl.gz or move it elsewhere to force rerun"
fi
