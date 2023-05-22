#!/usr/bin/env python
shell.executable('bash')


##### Identify if the fastq files need to be added together and add together if needed #####

##### Run STARsolo #####
if dataset_df.Technology.str.contains("10x_scATAC").all():
    rule cellranger_count:
        input:
        output:
            bam = outdir + '/{pool}/alignment_quantification/outs/possorted_genome_bam.bam',
            bai = outdir + '/{pool}/alignment_quantification/outs/possorted_genome_bam.bam.bai',
            matrix = outdir + '/{pool}/alignment_quantification/outs/filtered/matrix.mtx.gz',
            features = outdir + '/{pool}/alignment_quantification/outs/filtered/features.tsv.gz',
            barcodes = outdir + '/{pool}/alignment_quantification/outs/filtered/barcodes.tsv.gz',
            metrics = outdir + '/{pool}/alignment_quantification/outs/filtered/metrics_summary.csv',
            summary = outdir + '/{pool}/alignment_quantification/outs/filtered_feature_bc_matrix/web_summary.html',
            qstat = outdir + "/{pool}/qstat/cellranger_count.qstat",
        resources:
            mem_per_thread_gb=lambda wildcards, attempt: attempt * 12,
            disk_per_thread_gb=lambda wildcards, attempt: attempt * 64
        threads: 16
        params:
            fastqs = fastq_dir,
            cellranger_atac = "/directflow/SCCGGroupShare/projects/DrewNeavin/tools/cellranger-atac-2.1.0/cellranger-atac",
            reference = lambda wildcards: set(dataset_df[dataset_df.Dataset.str.contains(wildcards.dataset) & dataset_df.Seq_Technology.str.contains(wildcards.technology) & dataset_df.Pool.str.contains(wildcards.pool)].ref),
            outdir = outdir + '/datasets/{pool}/alignment_quantification/',
        shell:
            """
            cd {params.outdir}

            echo "Running ATAC cellranger"
            {params.cellranger_atac} count --id="{wildcards.dataset}" \ 
                --fastqs={params.fastqs} \
                --transcriptome={params.reference} \
                --jobmode=local \
                --localcores=16 \
                --localmem=256 \
                --nosecondary \
                --chemistry 'ARC-v1'      
            """


### will need to add visium etc here as well
else:
    rule STARsolo:
        input:
            qstat = lambda wildcards: expand(outdir + "/{{dataset}}/{{technology}}/{{pool}}/qstat/curl_{file}.qstat", file = dataset_df[dataset_df.Dataset.str.contains(wildcards.dataset) & dataset_df.Pool.str.contains(wildcards.pool)].file_name),
        output:
            bam = outdir + '/{pool}/alignment_quantification/outs/possorted_genome_bam.bam',
            bai = outdir + '/{pool}/alignment_quantification/outs/possorted_genome_bam.bam.bai',
            matrix = outdir + '/{pool}/alignment_quantification/outs/GeneFull/filtered/matrix.mtx.gz',
            features = outdir + '/{pool}/alignment_quantification/outs/GeneFull/filtered/features.tsv.gz',
            barcodes = outdir + '/{pool}/alignment_quantification/outs/GeneFull/filtered/barcodes.tsv.gz',
            qstat = outdir + "/{pool}/qstat/STARsolo.qstat",
        resources:
            mem_per_thread_gb=lambda wildcards, attempt: attempt * 24,
            disk_per_thread_gb=lambda wildcards, attempt: attempt * 128
        threads: 16
        params:
            outdir = outdir + '/{pool}/alignment_quantification/',
            index = "/directflow/SCCGGroupShare/projects/DrewNeavin/References/STAR_index",
            star = scai_dir + "/apps/STAR",
            seqtk = scai_dir + "/apps/seqtk",
            samtools = scai_dir + "/apps/samtools",
            fastqs = datadir + "/datasets/fastq/{pool}/",
            star_script_10x = scai_dir + "snakemake/scripts/starsolo_10x.sh",
            star_script_strt = scai_dir + "snakemake/scripts/starsolo_strt.sh",
            star_script_indrop = scai_dir + "snakemake/scripts/starsolo_indrop.sh",
            star_script_dropseq = scai_dir + "snakemake/scripts/starsolo_dropseq.sh",
            whitelist_dir = scai_dir + "/references/single_cell_barcode_whitelists/" + config['capture_technology'],
        shell:
            """
            if [[ {wildcards.technology} == "10x_3prime" || {wildcards.technology} == "10x_GE" ]]
            then
                echo "Running 10x STARsolo"

                bash {params.star_script_10x} \
                    {params.fastqs} \
                    {wildcards.pool} \
                    {params.index} \
                    {params.whitelist_dir}/10x/ \
                    3 \
                    {threads} \
                    $TMPDIR \
                    {params.star} \
                    {params.seqtk} \
                    {params.samtools}

            elif [[ {wildcards.technology} ==  "10x_5prime" ]]
            then
                echo "Running 10x STARsolo 5'"

                bash {params.star_script_10x} \
                    {params.fastqs} \
                    {wildcards.pool} \
                    {params.index} \
                    {params.whitelist_dir}/10x/ \
                    5 \
                    {threads} \
                    $TMPDIR \
                    {params.star} \
                    {params.seqtk} \
                    {params.samtools}

            elif [[ {wildcards.technology} ==  "STRT-seq" ]]
            then
                echo "Running STRT-seq STARsolo"

                bash {params.star_script_strt} \
                    {params.fastqs} \
                    {wildcards.pool} \
                    {params.index} \
                    {params.whitelist_dir}/STRT/ \
                    {threads} \
                    $TMPDIR \
                    {params.star} \
                    {params.samtools}
            
            elif [[ {wildcards.technology} ==  "inDrop" ]]
            then
                echo "Running inDrop STARsolo"

                bash {params.star_script_indrop} \
                    {params.fastqs} \
                    {wildcards.pool} \
                    {params.index} \
                    {params.whitelist_dir}/indrop/ \
                    {threads} \
                    $TMPDIR \
                    {params.star} \
                    {params.samtools}

            elif [[ {wildcards.technology} ==  "Drop-seq" ]]
            then
                echo "Running Drop-seq STARsolo"

                bash {params.star_script_dropseq} \
                    {params.fastqs} \
                    {wildcards.pool} \
                    {params.index} \
                    {threads} \
                    $TMPDIR \
                    {params.star} \
                    {params.samtools}

            elif [[ {wildcards.technology} == "SmartSeq" ]]
            then
                echo "Running SmartSeq STARsolo"
            fi

            rsync -avr \
                "$TMPDIR/" {params.outdir}

            mv {params.outdir}/Aligned.sortedByCoord.out.bam {output.bam}
            mv {params.outdir}/Aligned.sortedByCoord.out.bam.bai {output.bai}
            """

