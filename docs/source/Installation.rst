
.. _Install-docs:

==================================
Installation
==================================

We have prepared everything you need to run SCAI in a Singularity image - this is effective an image file that contains the required environment you need to run SCAI.

To get started using SCAI, please download the singularity image and accompanying md5sum file which contains all the tools and scripts required to run SCAI.


  .. code-block:: bash

    wget https://www.dropbox.com/s/4zaes24o985ore8/SCAI_base.sif
    wget https://www.dropbox.com/s/mf6b8v4w7h0voej/SCAI_base.sif.md5

Before moving forward, please check that the singularity image was downloaded correctly by comparing the md5sum in the md5 file to the md5sum of the downloaded singularity image.

  .. code-block:: bash

    md5sum SCAI.sif > downloaded_SCAI.sif.md5
    diff -s SCAI.sif.md5 downloaded_SCAI.sif.md5



If everything was downloaded correctly, that command should report:

  .. code-block:: bash

    Files SCAI.sif.md5 and downloaded_SCAI.sif.md5 are identical



.. note::

    Please note that the singularity image and this documentation is updated with each release. 
    This means that the most recent documentation may not be 100% compatible with the singularity image that you have.
    Please make sure you are using documentation that complements the singularity image you have or download the most recent version.


That's all you should need to do to run SCAI.

Happy analyzing!


Support
----------
If you're having trouble running SCAI, want to report bugs or have enhancement suggestions, feel free to submit an `issue <https://github.com/drneavin/scai/issues>`_.

