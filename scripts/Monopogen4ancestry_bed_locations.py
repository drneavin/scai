#!/usr/bin/env python3
"""
The main interface of scPopGene
"""

import argparse
import sys
import os
import logging
import shutil
import glob
import re
import pysam
import time
import subprocess
import pandas as pd
from pysam import VariantFile

LIB_PATH = os.path.abspath(
	os.path.join(os.path.dirname(os.path.realpath(__file__)), "pipelines/lib"))

if LIB_PATH not in sys.path:
	sys.path.insert(0, LIB_PATH)

PIPELINE_BASEDIR = os.path.dirname(os.path.realpath(sys.argv[0]))
CFG_DIR = os.path.join(PIPELINE_BASEDIR, "cfg")

#import pipelines
#from pipelines import get_cluster_cfgfile
#from pipelines import PipelineHandler

# global logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
handler = logging.StreamHandler()
handler.setFormatter(logging.Formatter(
	'[{asctime}] {levelname:8s} {filename} {message}', style='{'))
logger.addHandler(handler)




def print_parameters_given(args):
	logger.info("Parameters in effect:")
	for arg in vars(args):
		if arg=="func": continue
		logger.info("--{} = [{}]".format(arg, vars(args)[arg]))



def validate_user_setting(args):
	assert os.path.isfile(args.bamFile), "The bam list file {} cannot be found!".format(args.bamFile)
	assert os.path.isfile(args.reference), "The genome reference fasta file {} cannot be found!".format(args.reference)
	# assert os.path.isfile(args.imputation_panel), "Filtered genotype file of 1KG3 ref panel {} cannot be found!".format(args.imputation_panel)
	

def check_dependencies(args):
	programs_to_check = ("bgzip",  "bcftools", "beagle.27Jul16.86a.jar")

	for prog in programs_to_check:
		out = os.popen("command -v {}".format(args.app_path + "/" + prog)).read()
		assert out != "", "Program {} cannot be found!".format(prog)


def BamFilter(args):
	infile = pysam.AlignmentFile(args.bamFile,"rb")
	tp =infile.header.to_dict()
	if not "RG" in tp:
		sampleID = os.path.splitext(os.path.basename(args.bamFile))[0]
		tp1 = [{'SM':sampleID,'ID':sampleID, 'LB':"0.1", 'PL':"ILLUMINA", 'PU':sampleID}]
		tp.update({'RG': tp1})
	outfile =  pysam.AlignmentFile( args.out + "/Bam/" + args.chr + ".filter.bam", "wb", header=tp)
	for s in infile.fetch(args.chr):  
		#print(str(s.query_length)  + ":" + str(s.get_tag("AS")) + ":" + str(s.get_tag("NM")))
		if s.has_tag("NM"):
			val= s.get_tag("NM")
		if s.has_tag("nM"):
			val= s.get_tag("nM")                  
		if val < args.max_mismatch:
			outfile.write(s)
	infile.close()
	outfile.close()
	os.system(args.samtools + " index " +  args.out + "/Bam/" + args.chr + ".filter.bam")
	args.bam_filter = args.out + "/Bam/" + args.chr + ".filter.bam"


def robust_get_tag(read, tag_name):  
	try:  
		return read.get_tag(tag_name)
	except KeyError:
		return "NotFound"
    

def runCMD(cmd, args):
	#print(cmd)
	os.system(cmd + " > " + args.logfile)
	#process = subprocess.run(cmd, shell=True, stdout=open(args.logfile, 'w'), stderr=open(args.logfile,'w'))
	  

def SCvarCall(args):

	out = args.out
	logger.info("Preparing varint calling pipeline...")
	print_parameters_given(args)

	logger.info("Checking existence of essenstial resource files...")
	validate_user_setting(args)

	logger.info("Checking dependencies...")
	check_dependencies(args)

	os.system("mkdir -p " + out )
	os.system("mkdir -p " + out +  "/Bam")
	os.system("mkdir -p " + out +  "/SCvarCall")
	os.system("mkdir -p " + out +  "/Script" + args.chr)
	
	samtools = args.samtools 
	bcftools = args.bcftools 
	#java = os.path.abspath(args.app_path) + "/java"
	java =  args.java
	beagle = args.beagle

	logger.info("Filtering bam files...")
	BamFilter(args)   
	args.bam_filter = args.out + "/Bam/" + args.chr + ".filter.bam"
	cmd1 = samtools + " mpileup " + args.bam_filter + " -f "  + args.reference  + " -r " +  args.chr + " -l " + args.bed + " -q 20 -Q 20 -t DP -d 10000000 -v "
	cmd1 = cmd1 + " | " + bcftools + " view " + " | "  + bcftools  + " norm -m-both -f " + args.reference 
	cmd1 = cmd1 + " | grep -v \"<X>\" | grep -v INDEL |" + args.bgzip +   " -c > " + out + "/SCvarCall/" +  args.chr + ".gl.vcf.gz" 


	with open(out+"/Script" + args.chr + "/runBeagle.sh","w") as f_out:
		f_out.write(cmd1 + "\n")

	logger.info("Performing Variant Calling...")
	cmd = "bash " + out+"/Script" + args.chr +  "/runBeagle.sh"
	runCMD(cmd,args)


            
def main():
	parser = argparse.ArgumentParser(
		description="""Monopogen: SNV calling from single cell sequencing)
		""",
		epilog=
		"""Typical workflow: SCvarCall
		""",
		formatter_class=argparse.RawTextHelpFormatter)

	subparsers = parser.add_subparsers(title='Available subcommands', dest="subcommand")
	
	# every subcommand needs user config file
	common_parser = argparse.ArgumentParser(add_help=False)
	parser_varCall = subparsers.add_parser('SCvarCall', parents=[common_parser],
		help='Variant discovery, genotype calling from single cell data (scRNA-seq, snRNA-seq or snATAC-seq)',
		formatter_class=argparse.ArgumentDefaultsHelpFormatter)
	parser_varCall.add_argument('-b', '--bamFile', required=True,
								help="The bam file for the study sample, the bam file should be sorted")
	parser_varCall.add_argument('-c', '--chr', required= True, 
								help="The chromosome used for variant calling")
	parser_varCall.add_argument('-o', '--out', required= False,
								help="The output director")
	parser_varCall.add_argument('-r', '--reference', required= True, 
								help="The human genome reference used for alignment")
	parser_varCall.add_argument('-d', '--depth_filter', required=False, type=int, default=50,
								help="The sequencing depth filter for variants not overlapped with public database")
	parser_varCall.add_argument('-t', '--alt_ratio', required=False, type=float, default=0.1,
								help="The minina allele frequency for variants as potential somatic mutation")
	parser_varCall.add_argument('-m', '--max-mismatch', required=False, type=int, default=3,
								help="The maximal mismatch allowed in one reads for variant calling")
	parser_varCall.add_argument('-s', '--max-softClipped', required=False, type=int, default=1,
								help="The maximal soft-clipped allowed in one reads for variant calling")
	parser_varCall.add_argument('-a', '--app-path', required=True,
								help="The app library paths used in the tool")
	parser_varCall.add_argument('-e', '--bed', required=True,
								help="bed with locations for looking for snps")
	parser_varCall.set_defaults(func=SCvarCall)

	args = parser.parse_args()
	if args.subcommand is None:
		# if no command is specified, print help and exit
		print("Please specify one subcommand! Exiting!")
		print("-"*80)
		parser.print_help()
		exit(1)

	# execute subcommand-specific function
	args.logfile = args.out + "_" + args.chr + ".log"
	if os.path.exists(args.logfile):
		os.remove(args.logfile)
	handler1 = logging.FileHandler(args.logfile)
	handler1.setFormatter(logging.Formatter(
		'[{asctime}] {levelname:8s} {filename} {message}', style='{'))
	logger.addHandler(handler1)

	args.out = os.path.abspath(args.out)
	args.samtools  = "samtools" 
	args.bcftools = os.path.abspath(args.app_path) + "/bcftools"
	args.bgzip = os.path.abspath(args.app_path) + "/bgzip"
	args.java =  "java"
	args.beagle = os.path.abspath(args.app_path) + "/beagle.27Jul16.86a.jar"
	args.bamFile = os.path.abspath(args.bamFile)
	args.func(args)

	logger.info("Success! See instructions above.")

if __name__ == "__main__":
	main()
