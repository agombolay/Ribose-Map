![Logo](https://github.com/agombolay/Images/blob/master/Logo.png)
# A bioinformatics toolkit for mapping rNMPs in genomic DNA
**© 2017 Alli Gombolay, Fredrik Vannberg, and Francesca Storici**  
**School of Biological Sciences, Georgia Institute of Technology**

**If you use Ribose-Map, please use the following citation**:  
Gombolay, AL, FO Vannberg, and F Storici. Ribose-Map: a bioinformatics toolkit to map ribonucleotides embedded in genomic DNA. *Nucleic Acids Research*, Volume 47, Issue 1, 10 Jan 2019, Page e5, https://doi.org/10.1093/nar/gky874. 

## Modules
1. **Alignment**: Aligns reads to reference genome using [Bowtie2](http://bowtie-bio.sourceforge.net/bowtie2/index.shtml) and de-depulicates/de-multiplexes reads if needed
   * Output: BAM file of read alignments and log file with alignment statistics

2. **Coordinate**: Calculates single-nucleotide genomic coordinates of rNMPs based on aligned reads for any currently available rNMP sequencing technique: ribose-seq, emRiboSeq, RHII-HydEn-seq, Alk-HydEn-seq, and Pu-seq
   * Output: BED file of rNMP genomic coordinates and TAB files of rNMP counts

3. **Composition**: Calculates percentage of r[A, C, G, U] normalized to corresponding percentages of reference genome
   * Output: TXT files of raw counts and normalized frequencies for r[A, C, G, U] and barcharts of frequencies

4. **Sequence**: Calculates frequencies of A, C, G, U/T at rNMP sites and up to 100 bp up/downstream from those sites  
   * Output: TAB files of raw and normalized frequencies for A, C, G, U/T

5. **Distribution**:
   * Output: TAB, PNG, & BedGraph files of per-nucleotide rNMP coverage normalized to read depth  

6. **Hotspot**:
   * Output: PNG file of consensus sequence for top % most abundant sites of rNMP incorporation

## Required Files
1. FASTQ file of NGS rNMP-seq reads (SE or PE)
2. FASTA file of nucleotide sequence of reference genome
3. Chromosome sizes of reference genome (.chrom.sizes)
4. Bowtie2 index files of reference genome (.bt2)
5. [Configuration file](https://github.com/agombolay/ribose-map/blob/master/lib/sample.config)

**Note**: If you have a BED file of single-nucleotide genomic coordinates and want to input that file directly into the Sequence, Distribution, and Hotspot Modules, create a folder with the filepath below, save the file in this folder, and create a config file.

"$repository/results/$sample/coordinate$quality" ($variables should be those provided in config)

## Install Software

1. **Create conda software environment**:  
* To install conda, please visit [this link](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html)
* ribosemap_env.yaml is available [here](https://github.com/agombolay/ribose-map/blob/master/lib/ribosemap_env.yaml)
   ```bash
   conda env create --name ribosemap_env --file ribosemap_env.yaml
   ```

2. **Clone Ribose-Map GitHub repository**:  
* To install git, please visit [this link](https://git-scm.com/)
   ```bash
   git clone https://github.com/agombolay/ribose-map.git
   ```
   
## Run Ribose-Map
Before proceeding, close current terminal window and open a new window to refresh the settings  
* If SAMtools gives an error, then install this dependency: conda install -c conda-forge ncurses

1. **Activate environment to access software**:
```bash
source activate ribosemap_env
```

2. **Run scripts with configuration_file as input**:
```bash
ribose-map/modules/ribosemap {alignment, coordinate, composition, sequence, distribution, hotspot} config
```

3. **Once the analysis is complete, exit environment**:  
```bash
source deactivate ribosemap_env
```
