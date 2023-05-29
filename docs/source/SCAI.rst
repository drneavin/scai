.. _SCAI-docs:

==================================
Running SCAI
==================================

To run SCAI, you will need the following files:

.. _SCAI-required-files:

.. admonition:: Required Files
   :class: important

   - **Bam file**: aligned reads from single cell/nuclei experiment for a single individual
   - **Fasta file**: the fasta file used to align the reads for the bam file
   - **Bed file**: genetic variant locations in bed format (this can be downloaded from the :ref:`Resources <Resources-docs>` tab)
   - **Reference allele frequency file**: a file containing the allele frequencies for each variant location for each ancestral population - ideally the same locations as the bed file but not required (this can be downloaded for curated ancestral populations or generated from your own ancestral populations using instructions in the :ref:`Resources <Resources-docs>` tab)
   - **Reference N individuals file**: a file containing the number of individuals used to identify the allele frequencies in the **Reference allele frequency file** (this can be downloaded for curated ancestral populations or generated from your own ancestral populations using instructions in the :ref:`Resources <Resources-docs>` tab)


.. note::

    In future implementations, we would like to support multiplexed bam files but at this time only support bam files for single donors.
    However, if you demultiplex your data (for example with `Demuxafy <https://demultiplexing-doublet-detecting-docs.readthedocs.io/en/latest/>`_), you can split the bam for each donor using `sinto filterbarcodes <https://timoast.github.io/sinto/basic_usage.html#filter-cell-barcodes-from-bam-file>`_, an example is included in the :ref:`Resources <Resources-docs>`.



SCAI is split into two different execution command:
 
  1. :ref:`Variant calling <VariantCalling>` from bam a file (recommended to be run in parallel for each chromosome)
  2. :ref:`Ancestral admixture inference <AdmixtureInference>` using reference allele frequencies





.. _VariantCalling:

Variant Calling
----------------

.. admonition:: :octicon:`stopwatch` Expected Resource Usage
  :class: note

  ~XXX minutes when using XXX threads with XXXG memory each

Variants are called using an altered and abreviated version of `monopogen <https://github.com/KChen-lab/Monopogen>`_ and then are converted to beagle files containing genotype probability likelihoods.
We recommend running this step separately for each chromosome for each sample in parallel on a high performance cluster

To do this, run the ``scai_variants.sh`` script:

  .. code-block:: bash 

    singularity exec --bind /path/to/parent/directory SCAI.sif bash scai_variants.sh -b BAM -c CHR -e BED -f FASTA -o OUT

  - ``BAM`` is the bam file (see :ref:`Required Files <SCAI-required-files>`)
  - ``CHR`` is the chromosome ID you want to process (see :ref:`Required Files <SCAI-required-files>`)
  - ``BED`` is the bed file containing the genetic variant locations (see :ref:`Required Files <SCAI-required-files>`)
  - ``FASTA`` is the genome reference fasta used to align the bam file (see :ref:`Required Files <SCAI-required-files>`)
  - ``OUT`` is the output directory where a ``vcf.gz`` will be generated

 


.. _AdmixtureInference:

Ancestral Admixture Inference
---------------------------------

.. admonition:: :octicon:`stopwatch` Expected Resource Usage
  :class: note

  ~XXX minutes when using XXX threads with XXXG memory each


After that has completed for each of the chromosomes for a given ``BAM`` file, you can move on to SCAI ancestral admixture inference with ``scai_ancestry.sh``.
This script merges the different chromosome beagle files together and then estimates ancestral admixture using `fastNGSadmix <http://www.popgen.dk/software/index.php/FastNGSadmix>`_.

To do this, run the ``scai_ancestry.sh`` script:

  .. code-block:: bash

    singularity exec --bind /path/to/parent/directory SCAI.sif bash scai_ancestry.sh -o OUT -n FILE_NAME -f FREQ_FILE -i N_IND_FILE

  - ``OUT`` is the output directory where a ``scai_variants.sh`` results were written (and also where the results of ``scai_ancestry.sh`` will be written)
  - ``FILE_NAME`` is the base file name that will be used to write the output to in the ``OUT`` directory. The files that will be written will ``be OUT/FILENAME.qopt`` and ``OUT/FILENAME.log``.
  - ``FREQ_FILE`` is the file containing the allele frequency for each ancestral population in the format required by fastNGSadmix. (Can be downloaded for curated reference populations or generated for your own ancestral population data with code, see :ref:`Resources <Resources-docs>`).
  - ``N_IND_FILE`` is the number of individuals for each population included in the ``FREQ_FILE`` in the format required by fastNGSadmix. (Can be downloaded for curated reference populations or generated for your own ancestral population data with code, see :ref:`Resources <Resources-docs>`).
  - You can also pass ``-r "True"`` if you want to force rerun and write over previous results (otherwise disabled)


Results
---------------------------------

These commands will output multiple intermediary files but the most relevant for admixture inference results is:

  - ``FILE_NAME.qopt``: a tab separated file of the ancestral admixture (out of 1) for each of the ancestral populations provided in the ``FREQ_FILE`` and ``N_IND_FILE``. An example is:

    +--------------------+--------+---------+--------+-------------+---------+------------+
    | CENTRAL_SOUTH_ASIA | AFRICA | OCEANIA | EUROPE | MIDDLE_EAST | AMERICA | EAST_ASIA  |
    +====================+========+=========+========+=============+=========+============+
    | 0.7984             | 0.0165 | 0.1002  | 0.0000 | 0.0000      | 0.0000  | 0.0848     |
    +--------------------+--------+---------+--------+-------------+---------+------------+



.. note::

    In future implementations, we will provide result plotting as well.



Support
==================
If you're having trouble running SCAI, want to report bugs or have enhancement suggestions, feel free to submit an `issue <https://github.com/drneavin/scai/issues>`_.

