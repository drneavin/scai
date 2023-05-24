
.. _Install-docs:

==================================
Installation
==================================

To get started using SCAI, please clone the github repository which has the scripts and should include the required binaries for tools used.


.. code-block:: bash
    git clone -n --depth=1 --filter=tree:0 https://github.com/drneavin/scai.git
    cd scai
    git sparse-checkout set --no-cone scripts apps snakemake
    git checkout

 
These binaries are suitable for linux but may not work on all systems so if you run in to issues, the tools and versions are:

.. NOTE::
   On the to-do list is to prepare a docker and/or singularity image that has all the required softwares - let me know if you need this sooner rather than later.





Support
----------
If you're having trouble running SCAI, want to report bugs or have enhancement suggestions, feel free to submit an `issue <https://github.com/drneavin/scai/issues>`_.

