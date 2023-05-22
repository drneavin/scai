

BAM="--outSAMtype BAM SortedByCoordinate --outBAMsortingBinsN 500 --limitBAMsortRAM 60000000000 --outMultimapperOrder Random --runRNGseed 1 --outSAMattributes NH HI AS nM CB UB CR CY UR UY GX GN"



$STAR --runThreadN $CPUS --genomeDir $REF --readFilesManifest $SAMP.manifest.tsv --runDirPerm All_RWX $GZIP $BAM \
    --soloType SmartSeq --soloUMIdedup Exact --soloStrand Unstranded --clip3pAdapterSeq $ADAPTER \
    --soloFeatures GeneFull --soloOutFileNames output/ genes.tsv barcodes.tsv matrix.mtx



$STAR --runThreadN $CPUS --genomeDir $REF --readFilesIn $R2 $R1 --runDirPerm All_RWX $GZIP $BAM \
    --soloType SmartSeq --soloUMIdedup Exact --soloStrand Unstranded --clip3pAdapterSeq $ADAPTER \
    --soloFeatures GeneFull --soloOutFileNames outs/ genes.tsv barcodes.tsv matrix.mtx


