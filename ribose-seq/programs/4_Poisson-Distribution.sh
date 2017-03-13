#!/usr/bin/env bash

#© 2016 Alli Gombolay
#Author: Alli Lauren Gombolay
#E-mail: alli.gombolay@gatech.edu
#This program counts the number of windows in the genome with 0...X number of rNMPs

#Usage statement
function usage () {
	echo "Usage: Hotspots.sh [-i] 'Sample' [-r] 'Reference' [-s] 'Subset' [-d] 'Directory' [-h]
	-i Sample name (FS1, etc.)
	-s Subset of genome (sacCer2, nuclear, chrM, etc.)
	-r Reference genome assembly version (sacCer2, etc.)
	-d Local directory (/projects/home/agombolay3/data/repository/Ribose-seq-Project)"
}

#Command-line options
while getopts "i:s:r:d:h" opt; do
    case $opt in
        #Allow multiple input arguments
        i ) sample=($OPTARG) ;;
	#Allow only one input argument
	s ) subset=$OPTARG ;;
	r ) reference=$OPTARG ;;
	d ) directory=$OPTARG ;;
        #Print usage statement
        h ) usage ;;
    esac
done

#Exit program if [-h]
if [ "$1" == "-h" ]; then
        exit
fi

#############################################################################################################################
#Input files
referenceBed=$directory/ribose-seq/reference/$reference.bed
sorted=$directory/ribose-seq/results/$reference/$sample/Coordinates/$subset/$sample.rNMP-coordinates.sorted.bed

#Output directories
output1=$directory/ribose-seq/reference; output2=$directory/ribose-seq/results/$reference/$sample/Poisson

#Create directories
mkdir -p $output1 $output2

#Output files
binned=$output2/$sample.binned-data.txt
counts=$output2/$sample.Poisson-windows.txt
referenceWindows=$output1/$reference.windows.bed

#Separate reference genome into 2.5 kb windows
bedtools makewindows -g $referenceBed -w 2500 > $referenceWindows

#Select only data of interest (nuclear or mitochondrial DNA)
#Determine regions of BED files that intersect and count number of intersections
#Remove rows where window size is < 2.5 kb and sort based on # of rNMPs in windows
if [ $subset == "nuclear" ]; then
	bedtools intersect -a $referenceWindows -b $sorted -c -sorted -nonamecheck \
	| grep -v 'chrM' - | awk '{ $5 = $3 - $2 } 1' - | awk -v OFS='\t' '($5 == 2500 )  \
	{print $1,$2,$3,$4}' - | sort -k4 -n - > temporary

elif [ $subset == "chrM" ]; then
	bedtools intersect -a $referenceWindows -b $sorted -c -sorted -nonamecheck \
	| grep 'chrM' - | awk '{ $5 = $3 - $2 } 1' - | awk OFS='\t' '($5 == 2500 ) \
	{print $1,$2,$3,$4}' - | sort -k4 -n - > temporary
fi

#Maximum number of rNMPs in binned data file
max=$(tail -1 temporary | awk '{print $4}' -)

#Determine number of windows with 0...maximum rNMPs
for i in $(seq 0 $max); do
	windows+=($(awk '$4 == ('$i')' temporary | wc -l))
done

#Add column names to file
echo -e "Chr\tStart\tStop\trNMPs" > $binned && cat temporary >> $binned

#Add column names and number of windows with 0...maximum rNMPs
echo -e "rNMPs\tWindows" > $counts && paste <(echo "$(seq 0 $max)") \
<(cat <( IFS=$'\n'; echo "${windows[*]}" )) >> $counts

#Remove temporary file
rm temporary
