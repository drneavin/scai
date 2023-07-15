
.. _Install-docs:

==================================
Installation
==================================

We have prepared everything you need to run scadmix in a Singularity or docker image - this is effective an image file that contains the required environment you need to run scadmix.

To get started using scadmix, please download the singularity image and accompanying md5sum file which contains all the tools and scripts required to run scadmix.


  .. code-block:: bash

    wget https://www.dropbox.com/s/fcs090b0eb5owqj/scadmix.sif
    wget https://www.dropbox.com/s/rft14hscfea5r4m/scadmix.sif.md5

Before moving forward, please check that the singularity image was downloaded correctly by comparing the md5sum in the md5 file to the md5sum of the downloaded singularity image.

  .. code-block:: bash

    md5sum scadmix.sif > downloaded_scadmix.sif.md5
    diff -s scadmix.sif.md5 downloaded_scadmix.sif.md5



If everything was downloaded correctly, that command should report:

  .. code-block:: bash

    Files scadmix.sif.md5 and downloaded_scadmix.sif.md5 are identical



.. note::

    Please note that the singularity image and this documentation is updated with each release. 
    This means that the most recent documentation may not be 100% compatible with the singularity image that you have.
    Please make sure you are using documentation that complements the singularity image you have or download the most recent version.


.. _SingImages:

Using Singularity Images
===========================

Singularity images contain an specific environment. In this case, I've built the required software and scripts into the ``scadmix.sif`` singularity image.
To run a command using the singularity image:

  .. code-block:: bash

    singularity exec scadmix.sif command ...

One tricky bit about singularity images, is that they will only load the local file system that is below the location of the singularity image.
However, we typically have to load files from different locations on the files system.
We can do this by using the ``--bind`` flag to load different areas of the filesystem:

  .. code-block::  bash

    singularity exec --bind /path scadmix.sif command ...

You will receive an error telling you the file doesn't exist if you haven't bound the correct required directories.
We typically bind the top-most directory that contains all our files but you can also bind multiple directories with ``--bind /path1,/path2``


That's all you should need to run scadmix. 
Resources that can be used to run scadmix are also available on the  :ref:`Resources <Resources-docs>` page.

Happy analyzing!


Support
----------
If you're having trouble running scadmix, want to report bugs or have enhancement suggestions, feel free to submit an `issue <https://github.com/drneavin/scadmix/issues>`_.

