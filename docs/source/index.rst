.. SCAI: Single Cell Admixture Inference documentation master file, created by
   sphinx-quickstart on Tue May 23 09:58:21 2023.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

SCAI: Single Cell Admixture Inference
=========================================================================


Motivation
---------------
Single cell or nuclei datasets have been generated for thousands of samples and continues to be a highly-utilized technology for biological insights.
Further, many of these data are being used as atlases - references for understanding basic biological pathways about different cell types and in different contexts (*i.e.* during disease or drug treatment).
However, not all factors that influence transcriptional profiles are ascertained about each donor when samples are collected.
For example, ancestry and sex of the donor can contribute to variation in gene expression and incomplete annotation of these may lead to misleading or incomplete interpretations of results.

Even when sex information is not collected for a donor when samples are collected, sex can be easily annotated by interrorgating the X and Y chromosome genes that are expressed.
However, the ancestral admixture of each donor has been more challenging to estimate and may be an important hidden factor in gene expression differences.

Here, we present SCAI (pronounced sky) a tool for **S**\ ingle **C**\ ell **A**\ dmixture **I**\ nference to estimate ancestry admixture which can be run as a stand-alone tool on a bam of aligned reads (see :ref:`Running SCAI <SCAI-docs>`). 
We have also built SCAI into a Snakemake pipeline that can be applied to fastq files that does read alignnment followed by ancestry admixture estimation (see :ref:`Snakemake Pipeline <Snakemake-docs>`). 


 
.. toctree::
   :maxdepth: 2
   :caption: Contents: 

   Installation
   SCAI
   Snakemake


Support
==================
If you're having trouble running SCAI, want to report bugs or have enhancement suggestions, feel free to submit an `issue <https://github.com/drneavin/scai/issues>`_.


.. Citation
.. --------
