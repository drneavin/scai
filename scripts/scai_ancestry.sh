#!/bin/bash -e 

## single cell admixture inference (scai) pipeline
## Used to infer ancestral admixture in single-cell data
## scai ancestry uses fastNGSadmix to estimate ancestral admixture.


show_help() {
cat << EOF
Usage: ${0##*/} [-hv] -o OUT -n FILE_NAME -f FREQ_FILE -i N_IND_FILE
scai: single cell admixture inference pipeline

Call genetic variants for a sample from a bam file and convert to a beagle format for admixture inference with scai_ancestry


    -h              Display this help and exit. 
    -d DIR          Path to directory containing scai_variants results. This should be the same path used for OUTDIR for scari_variants. Required.
    -n FILE_NAME    Name of file to be written at OUT. The files that will be written will be OUT/FILENAME.qopt and OUT/FILENAME.log. Required.
    -f FREQ_FILE    The file containing the frequency for each population in the format required by fastNGSadmix. Files for different human genome versions are provided and can be downloaded on the scai documentation.
    -i N_IND_FILE   The number of individuals for each population included in the FREQ_FILE in the format required by fastNGSadmix. Files for different human genome versions can be downloaded on the scai documentation.
    -r FORCED   Whether the jobs should be forced to rerun even if the output file exists. Defaults to "False" but can also be set to "True". Optional
EOF
}


while getopts ":h:o:n:f:i:r:" opt; do
  case $opt in
    h) 
        show_help
        exit 0
        ;;
    o) OUT="$OPTARG"
    ;;
    n) FILE_NAME="$OPTARG"
    ;;
    f) FREQ_FILE="$OPTARG"
    ;;
    i) N_IND_FILE="$OPTARG"
    ;;
    r) FORCED="$OPTARG"
    ;;
    :) FORCED="False"
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

printf "Using directory: %s\n" "$OUT"
printf "Writing results with filename: %s\n" "$FILE_NAME"
printf "Using this frequency file: %s\n" "$FREQ_FILE"
printf "Using this file with the number of individuals for the frequency file: %s\n" "$N_IND_FILE"





##### 3. Merge the different beagle files together and gzip
### if beagle merging hasn't been run, then run it
if [[ ! -f $OUT/beagle/beagle.gl.gz ]] || [[ $FORCED == "True" ]]
then
    echo "Generating combined beagle file"

    head_file=`ls $OUT/beagle/*.beagle.gl | cut -d' ' -f1 | head -n 1`
    head -n 1 $head_file > $OUT/beagle/beagle.gl
    tail -n +2 $OUT/beagle/*.beagle.gl >> $OUT/beagle/beagle.gl
    sed -i '/^$/d' $OUT/beagle/beagle.gl
    sed -i '/==>/d' $OUT/beagle/beagle.gl
    sed -i '/ N /d' $OUT/beagle/beagle.gl
    sed -i 's/:[ACTG]:[ACTG] / /g' $OUT/beagle/beagle.gl
    sed -i 's/:/_/g' $OUT/beagle/beagle.gl
    sed -i 's/ /\t/g' $OUT/beagle/beagle.gl
    sed -i 's/^chr//g' $OUT/beagle/beagle.gl
    gzip $OUT/beagle/beagle.gl

    echo "Done! Beagle files have been merged."

else
    echo "Looks like the beagle files have already been merged."
    echo "If you want to rerun this step, either us '-b True' or remove the file beagle.gl.gz or move it elsewhere to force rerun"
fi




##### 3. Run fastNGSadmix
if [[ ! -f $OUT/$FILE_NAME.qopt ]] || [[ $FORCED == "True" ]]
then
    echo "Running fastNGSadmix for ancestry admixture estimation."

    fastNGSadmix -likes $OUT/beagle/beagle.gl.gz -fname $FREQ_FILE -Nname $N_IND_FILE -out $OUT/$FILE_NAME -whichPops 'all'


  if [ -f $OUT/$FILE_NAME.qopt ]
  then
      echo "Done! fastNGSadmix for ancestry admixture estimation has completed."
  else
      echo "Looks like fastNGSadmix failed, please check the logs for errors and rerun once fixed"
  fi

else
    echo "Looks like fastNGSadmix has already been written to this file name ($OUT/$FILE_NAME)."
    echo "If you want to rerun this step, either us '-b True' or remove the file beagle.gl.gz or move it elsewhere to force rerun."
fi
