#!/usr/bin/env python
shell.executable('bash')


rule monopogen:
    input:
        bam = outdir + '/{pool}/alignment_quantification/outs/possorted_genome_bam.bam',
        bai = outdir + '/{pool}/alignment_quantification/outs/possorted_genome_bam.bam.bai',
    output:
        # bam = temp(outdir + "/{pool}/bams/{chr}.bam"),
        done = outdir + "/{pool}/SCvarCall/{chr}.done",
        qstat = outdir + "/{pool}/qstat/monopogen_{chr}.qstat",
        gl = outdir + "/{pool}/SCvarCall/{chr}.gl.vcf.gz",
    resources:
        mem_per_thread_gb=lambda wildcards, attempt: attempt * 5,
        disk_per_thread_gb=lambda wildcards, attempt: attempt * 5
    threads: 4
    params:
        scai_dir = scai_dir,
        fasta = fasta,
        out =  outdir + "/{pool}/",
        bed = config['bed'],
        script = scai_dir + "/scripts/Monopogen4ancestry_bed_locations.py",
    shell:
        """
        export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:{params.scai_dir}/apps/

        bed=`echo {params.bed} | sed 's/{{chr}}/{wildcards.chr}/g'`

        python {params.script} SCvarCall \
            -b {input.bam} \
            -a {params.scai_dir}/apps/ \
            -c {wildcards.chr} \
            -o {params.out} \
            -r {params.fasta} \
            -d 100 \
            -t 0.1 \
            -m 3 \
            -s 1 \
            -e $bed

        echo "monopogen comeplete" > {output.done}
        """


rule samtools2beagle:
    input:
        done = outdir + "/{pool}/SCvarCall/{chr}.done",
        gl = outdir + "/{pool}/SCvarCall/{chr}.gl.vcf.gz"
    output:
        gl = temp(outdir + "/{pool}/{chr}.beagle.gl"),
        qstat = outdir + "/{pool}/qstat/samtools2beagle_{chr}.qstat",
    resources:
        mem_per_thread_gb=lambda wildcards, attempt: attempt * 128,
        disk_per_thread_gb=lambda wildcards, attempt: attempt * 128
    threads: 4
    params:
        beagle = "/directflow/SCCGGroupShare/projects/DrewNeavin/software/Monopogen/apps/beagle.27Jul16.86a.jar",
    shell:
        """
        perl /directflow/SCCGGroupShare/projects/DrewNeavin/software/vcf2beagle_edited.pl --in={input.gl} --out={output.gl} --PL
        """


rule merge_beagle_filtered:
    input:
        lambda wildcards: expand(outdir + "/{{dataset}}/{{technology}}/{{pool}}/{chr}.beagle.gl", chr = [(', '.join(set(dataset_df[dataset_df.Dataset.str.contains(wildcards.dataset) & dataset_df.Pool.str.contains(wildcards.pool)].chr)) + str(x)) for x in list(range(1,23))])
    output:
        bgl = outdir + "/{pool}/beagle.gl.gz",
        qstat = outdir + "/{pool}/qstat/merge_beagle_filtered.qstat",
    resources:
        mem_per_thread_gb=lambda wildcards, attempt: attempt * 128,
        disk_per_thread_gb=lambda wildcards, attempt: attempt * 128
    threads: 4
    params:
        out = outdir + "/{pool}/beagle.gl",
        outdir = outdir + "/{pool}/",
    shell:
        """
        head_file=`ls {input} | cut -d' ' -f1 | head -n 1`
        head -n 1 $head_file > {params.out}
        tail -n +2 {input} >> {params.out}
        sed -i '/^$/d' {params.out}
        sed -i '/==>/d' {params.out}
        sed -i '/ N /d' {params.out}
        sed -i 's/:[ACTG]:[ACTG] / /g' {params.out}
        sed -i 's/:/_/g' {params.out}
        sed -i 's/ /\\t/g' {params.out}
        sed -i 's/^chr//g' {params.out}
        gzip {params.out}
        """


rule samtools_fastNGSadmix_continental:
    input:
        beagle = outdir + "/{pool}/beagle.gl.gz",
        ref_freq = config['ref_freq'],
        n_ind = config['n_Ind']
    output:
        out = outdir + "/{pool}/continental_admixture.qopt",
        qstat = outdir + "/{pool}/qstat/samtools_fastNGSadmix_continental.qstat",
    resources:
        mem_per_thread_gb=lambda wildcards, attempt: attempt * 16,
        disk_per_thread_gb=lambda wildcards, attempt: attempt * 16
    threads: 2
    params:
        out = outdir + "/{pool}/continental_admixture"
    shell:
        """
        /directflow/SCCGGroupShare/projects/software/fastNGSadmix/fastNGSadmix -likes {input.beagle} -fname {input.ref_freq} -Nname {input.n_ind} -out {params.out} -whichPops 'all'
        """

