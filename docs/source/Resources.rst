.. _Resources-docs:

==================================
Resources
==================================

Here we provide some prepared files that you can use for running SCAI.
We also provide some code examples for additional pre-processing that may be required to run SCAI

.. note::

  We have generated reference files for GRCh38 to-date but on the to-do list is to generate references and bed files for hg19 as well.



Pre-generated Ancestral Population References
===================================================

Ancestral population references have been generated using the `Human Genome Diversity Panel  <https://www.internationalgenome.org/data-portal/data-collection/hgdp>`_.
Three different references have been generated:

  - Continental (Central South Asia, Africa, Oceaniam, Europe, Middle East, Americas and East Asia)
  - Continental without Middle East (Central South Asia, Africa, Oceaniam, Europe, Americas and East Asia)
  - Subcontinental which includes the regional collection site locations for each group of donors

We have endeavored to remove any samples that may have admixture or ancestral admixture from the continental-level references in order to remove noise from the reference.
However, the subcontinental data have not been pruned except for donors that appeared to have admixture.

Download whichever reference is relevant for your data depending on the genome version your data is aligned to.

We provide some brief instructions on generating your own reference if you like :ref:`Generating Ancestral Population Reference <generate_anc_ref>`

Continental with Middle East
-------------------------------

No 'chr' Encoding
++++++++++++++++++++++

https://www.dropbox.com/s/r7rg4c7r1ej8or3/continental_w_middle_east-GRCh38-no_chr.tar.gz

With 'chr' Encoding
++++++++++++++++++++++

https://www.dropbox.com/s/3c4kdyzdwyy3p3m/continental_w_middle_east-GRCh38-chr.tar.gz




Continental without Middle East
----------------------------------

No 'chr' Encoding
++++++++++++++++++++++

https://www.dropbox.com/s/qa2zsmkmib0dfgf/continental_no_middle_east-GRCh38-no_chr.tar.gz


With 'chr' Encoding
++++++++++++++++++++++

https://www.dropbox.com/s/nkx8d8cqmryyosh/continental_no_middle_east-GRCh38-chr.tar.gz




Subcontinental
----------------------------------

No 'chr' Encoding
++++++++++++++++++++++

https://www.dropbox.com/s/fofyirjxnlmytme/subcontinental-GRCh38-no_chr.tar.gz

With 'chr' Encoding
++++++++++++++++++++++

https://www.dropbox.com/s/92spxqqgz7dgl9c/subcontinental-GRCh38-chr.tar.gz




Bed Files for Pre-generated Ancestral Population References
=============================================================


The pipeline requires bed files to identify the locations across the genome that will be interrogated for variation.
Only the locations that are in the Pre-generated Ancestral Population references are included in the provided bed files (since other locations couldn't be used).



GRCh38 without 'chr' Encoding
----------------------------------

https://www.dropbox.com/s/b1gphcn5ty4e8qm/GRCh38_no_chr_beds.tar.gz


GRCh38 with 'chr' Encoding
----------------------------------

https://www.dropbox.com/s/gt9a8n6thzwaysk/GRCh38_chr_beds.tar.gz



.. _generate_anc_ref:


Generating Ancestral Population Reference
===================================================
If you would like to generate your own reference, you can convert plink files to reference files following  the instructions on `fastNGSadmix <http://www.popgen.dk/software/index.php/FastNGSadmix>`_.
The scripts required are already provided in the singularity image at ``/opt/fastNGSadmix/R/plinkToRef.R`` so you can run this with:

.. code-block:: bash

  singularity exec SCAI.sif Rscript /opt/fastNGSadmix/R/plinkToRef.R /path/to/plink 1 0.01




Split Multiplexed Bam with sinto
=============================================================

We aim to support multiplexed bams in the future but currently only support single-sample bams.
If your bam file contains multiplexed samples from different donors, you can demultiplex your data (for example with `Demuxafy <https://demultiplexing-doublet-detecting-docs.readthedocs.io/en/latest/>`_) and use that inforamtion to  split the bam for each donor using `sinto filterbarcodes <https://timoast.github.io/sinto/basic_usage.html#filter-cell-barcodes-from-bam-file>`_.

In preparation for this step, we set some additional parameters and create the required output directory.
The parameters that we use for the command in this step are 

.. code-block:: bash

  BAM=/path/to/bam/file.bam ### Path to bam file
  ANNO_BARCODES=/path/to/annotated/barcodes.tsv ### Path to annotated barcodes
  TAG="CB"
  N=8

  mkdir -p $OUTDIR/bams

- The ``$TAG`` is the tag used in your bam file to indicate cell barcodes. In 10x captures, this is 'CB' but could be different for different technologies

- The ``$ANNO_BARCODES`` is a tab-separated file that has the barcodes in the first column and the IDs of the individual that they are assigned to in the second column. This file should NOT have a header. For example:

  +--------------------+--------------+
  | AAACCCAAGAACTGAT-1 |      K835-8  |
  +--------------------+--------------+
  | AAACCCAAGAAGCCTG-1 |      K1292-4 |
  +--------------------+--------------+
  | AAACCCAAGCAGGTCA-1 |      K1039-4 |
  +--------------------+--------------+
  | AAACCCAAGCGGATCA-1 |      K962-0  |
  +--------------------+--------------+
  | AAACCCAAGCTGCGAA-1 |      K835-8  |
  +--------------------+--------------+
  | AAACCCAAGGTACTGG-1 |      K1292-4 |
  +--------------------+--------------+
  | AAACCCAAGTCTTCCC-1 |      K835-8  |
  +--------------------+--------------+
  | AAACCCACAACCGCCA-1 |      K835-8  |
  +--------------------+--------------+
  | AAACCCACACAGTGAG-1 |      K962-0  |
  +--------------------+--------------+
  | AAACCCACACCCTGAG-1 |      K835-8  |
  +--------------------+--------------+
  | ...                |      ...     |
  +--------------------+--------------+



To divide the bam file into a single file for each individual in the pool, simply execute:

.. code-block:: bash

   
  sinto filterbarcodes -b $BAM -c $ANNO_BARCODES --barcodetag $TAG --outdir $OUTDIR/bams --nproc $N
   