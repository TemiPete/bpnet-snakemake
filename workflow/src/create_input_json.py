import argparse, os, sys, json
import pandas as pd
import numpy as np

import pathlib
script_dir = pathlib.Path(__file__).parent.resolve() # the directory of the script

parser = argparse.ArgumentParser()
parser.add_argument("--find_outliers", action='store_true', help="", default=False)
parser.add_argument("--signal_source", type = str, help="path to file with signal")
parser.add_argument("--loci_source", type = str, help="path to file with loci")
parser.add_argument("--background_loci_source", type = str, help="path to file with background loci", default = None)
parser.add_argument("--bias_source", type = str, help="path to file with bias", default = None)
parser.add_argument("--output_json", type = str, help="path to output json file", default = None)

args = parser.parse_args()

if args.find_outliers:
    out = dict()
    out['0'] = dict()
    out['0']['signal'] = dict()
    out['0']['loci'] = dict()

    # add
    out['0']['signal']['source'] = [args.signal_source]
    out['0']['loci']['source'] = [args.loci_source]

    # write out
    with open(args.output_json, 'w') as f:
        json.dump(out, f)
        print(f'INFO - Finished saving data to {args.output_json}')
else:
    out = dict()
    out['0'] = dict()
    out['0']['signal'] = dict()
    out['0']['loci'] = dict()
    out['0']['background_loci'] = dict()
    out['0']['bias'] = dict()

    # add
    out['0']['signal']['source'] = [args.signal_source]
    out['0']['loci']['source'] = [args.loci_source]
    out['0']['background_loci']['source'] = [args.background_loci_source]
    out['0']['bias']['source'] = [args.bias_source]

    out['0']['background_loci']['ratio'] = [0.25]
    out['0']['bias']['smoothing'] = [None]

    # write out
    with open(args.output_json, 'w') as f:
        json.dump(out, f)
        print(f'INFO - Finished saving data to {args.output_json}')
