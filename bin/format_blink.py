#!/usr/bin/python


import sys
import getopt
import os
import pandas as pd
from collections import defaultdict
import argparse
import glob

def _parse_file(input_filename):
    # checking extension
    if input_filename.endswith(".tsv"):
        df = pd.read_csv(input_filename, sep="\t")
    elif input_filename.endswith(".csv"):
        df = pd.read_csv(input_filename, sep=",")

    return df


def main():
    # Parsing the arguments
    parser = argparse.ArgumentParser(description='Formatting data results')
    parser.add_argument('input_blink_file', help='input_blink_file')
    parser.add_argument('output_file', help='output_file')

    args = parser.parse_args()

    df = _parse_file(args.input_blink_file)

    df["SpectrumFile"] = df["query_filename"]
    df["#Scan#"] = df["query_id"]
    df["MQScore"] = df["rem_predicted_score"]
    df["FileScanUniqueID"] = df["SpectrumFile"].astype(str) + ":" + df["#Scan#"].astype(str)
    df["LibrarySpectrumID"] = df["ref_id"]

    # Boiler plate
    df["LibraryName"] = df["ref_filename"]
    df["UnstrictEvelopeScore"] = 0
    df["p-value"] = 0
    df["Charge"] = 0
    df["SpecMZ"] = 0
    df["mzErrorPPM"] = 0
    df["LibSearchSharedPeaks"] = 0
    df["ParentMassDiff"] = 0


    # Outputting
    df.to_csv(args.output_file, sep="\t", index=False)

if __name__ == "__main__":
    main()
