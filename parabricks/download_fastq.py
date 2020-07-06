#!/usr/bin/env python3
#
# Copyright (c) 2019 Dell Inc., or its subsidiaries. All Rights Reserved.
#
# Written by Damien Mas <damien.mas@dell.com>
#

import os
import glob
import re
import shutil
import logging
import sys
import time
import subprocess
import configargparse
import hashlib

env = os.environ.copy()

def md5(fname):
    hash_md5 = hashlib.md5()
    with open(fname, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

def create_dir(dirName, overwrite=True):
    if not os.path.exists(dirName):
        os.makedirs(dirName)
        logging.info('Directory %s created' % dirName)
    else:
        logging.info('Directory %s already exists' % dirName)
        if overwrite is True:
            try:
                shutil.rmtree(dirName)
                logging.info('Directory %s deleted' % dirName)
                os.makedirs(dirName)
                logging.info('Directory %s created' % dirName)
            except OSError as e:
                print("Error: %s : %s" % (dirName, e.strerror))


def main():

    parser = configargparse.ArgParser(
        description='download fastq files for parabricks',
        config_file_parser_class=configargparse.YAMLConfigFileParser,
    )
    parser.add('--config', '-c', default='download_fastq.yaml',
               required=False, is_config_file=True, help='config file path (default=download_fastq.yaml)')
    parser.add('--list_ref_file', default='download_fastq.csv', help='Temp directory')
    parser.add('--ref_temp_dir', default='/tmp/download_ref', help='Temp directory')
    parser.add('--output_fastq_dir', default='/mnt/isilon/genomics/fastq', help='Temp directory', required=True)
    parser.add('--log_level', type=int, default=logging.INFO, help='10=DEBUG,20=INFO,30=WARNING,40=ERROR,50=CRITICAL')
    args = parser.parse_args()

    root_logger = logging.getLogger()
    root_logger.setLevel(args.log_level)
    console_handler = logging.StreamHandler(sys.stdout)
    logging.Formatter.converter = time.gmtime
    console_handler.setFormatter(logging.Formatter('%(asctime)s %(message)s'))
    root_logger.addHandler(console_handler)

    create_dir(args.ref_temp_dir)
    create_dir(args.output_fastq_dir, overwrite=False)
    # parse list of references to download
    # Example : LIBRARY_ID\tURL\tCOVERAGE
    # LP6005441-DNA_A10	https://www.ebi.ac.uk/ena/data/view/ERR1419095  33.59
    sample_records = []
    with open(args.list_ref_file, 'r') as f:
        sample_records += [line.rstrip('\n').split('\t') for line in f if '#' not in line]
    
    # dowload list of fastq files
    map_id = {}
    URL_FASTQ_MD5_PREFIX="https://www.ebi.ac.uk/ena/data/warehouse/filereport?accession="
    URL_FASTQ_MD5_SUFFIX="&result=read_run&fields=fastq_ftp,fastq_md5&download=txt"
    for item in sample_records:
        ID = item[1].split('/')
        map_id[ID[-1]] = item[0]
        #map_id[item[0]] = ID[-1]
        output_file_path = os.path.join(args.ref_temp_dir, ID[-1])

        cmd = ['wget', '--no-verbose', '-t', '0', '-c', '-O', output_file_path, URL_FASTQ_MD5_PREFIX + ID[-1] + URL_FASTQ_MD5_SUFFIX]
        logging.debug(cmd)
        out = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout,stderr = out.communicate()

        if out.returncode != 0:
            logging.info('%s download failed: %s' % (ID[-1],stderr.strip().decode("utf-8")))
        else:
            logging.info('%s downloaded successfully under %s' % (ID[-1],output_file_path))
            create_dir(os.path.join(args.output_fastq_dir,item[0]), overwrite=False)

    # Extract url info from each downloaded fastq
    download_fastq = []
    filenames = glob.glob(os.path.join(args.ref_temp_dir, '*'))
    for item in filenames:
        if os.path.isfile(item):
            fastqid = item.split('/')[-1]
            with open(item, 'r') as f:
                header_line = next(f)
                a = re.split(';|\t', f.readline().rstrip())
                download_fastq += [
                     {'id': map_id[fastqid], 'filename': a[0].split('/')[-1], 'url': a[0], 'md5': a[2]},
                     {'id': map_id[fastqid], 'filename': a[1].split('/')[-1], 'url': a[1], 'md5': a[3]}
                     ]

    # generate wget commands and write into a file /tmp/download_fastq
    list_cmds = []
    for item in download_fastq:
        file_path = os.path.join(args.output_fastq_dir, item['id'], item['filename'])
        cmd = '--no-verbose -c -T 60 -t 0 -O %s %s' % (file_path, item['url'])
        list_cmds += [ cmd ]

    print('Downloading %s files ...' % len(download_fastq))

    with open('/tmp/download_fastq', 'w') as f:
        f.write('\n'.join(list_cmds))

    # Run all downloads in parallel using xargs
    # cat /tmp/download_fastq | xargs -i -P 0 wget {}
    cmd = ['cat', '/tmp/download_fastq']
    proc_cat = subprocess.Popen(cmd, stdout=subprocess.PIPE)
    proc_wget = subprocess.Popen(["xargs", "-i", "-L", "1", "-P", "0", "wget"], stdin=proc_cat.stdout, stdout=subprocess.PIPE)
    proc_cat.stdout.close()
    output = proc_wget.communicate()[0]

    # Verify checksum for each downloaded files
    logging.info("Verifying MD5SUM ...")
    for item in download_fastq:
        file_path = os.path.join(args.output_fastq_dir, item['id'], item['filename'])
        md5_result = md5(file_path)
        # print(md5_result)
        if md5_result == item['md5']:
            logging.info("%s md5sum OK" % file_path)
        else:
            logging.error("%s md5sum KO" % file_path)


if __name__ == '__main__':
    main()
