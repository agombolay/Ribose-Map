#!/usr/bin/env bash
#Author: Alli Gombolay
#This program calculates the ribonucleotide frequencies located at 3' position of input BED file

#COMMAND LINE OPTIONS

#Usage statement of the program
function usage () {
	echo "Usage: 5_Ribonucleotide-Frequencies.sh [-i] 'Sample' [-r] 'Reference' [-s] 'Subset' [-d] 'Directory' [-h]
	-i Sample name (FS1, etc.)
	-s Subset of genome (sacCer2, nuclear, mitochondria)
	-r Reference genome assembly version (sacCer2, etc.)
	-d Local directory ('/projects/home/agombolay3/data/repository/Ribose-seq-Project')"
}

#Use getopts function to create the command-line options ([-i], [-s], [-r], [-d], and [-h])
while getopts "i:s:r:d:h" opt;
do
    case $opt in
        #Specify input as arrays to allow multiple input arguments
        i ) sample=($OPTARG) ;;
	#Specify input as variable to allow only one input argument
	s ) subset=$OPTARG ;;
	r ) reference=$OPTARG ;;
	d ) directory=$OPTARG ;;
        #If user specifies [-h], print usage statement
        h ) usage ;;
    esac
done

#Exit program if user specifies [-h]
if [ "$1" == "-h" ];
then
        exit
fi

#Location of "Alignment" directory
directory1=$directory/ribose-seq/results/$reference/$sample/Alignment

#Location of "Nucleotide-Frequencies" directory
directory2=$directory/ribose-seq/results/$reference/$sample/Nucleotide-Frequencies

##############################################################################################################################
#STEP 1: Covert BAM file to FASTA format

#Location of input BAM file
bam=$directory1/$sample.bam

#Location of output directory
output1=$directory2/Ribonucleotides/$subset

#Create directory for output if it does not already exist
if [[ ! -d $output1 ]];
then
	mkdir -p $output1
fi
	
fastq=$output1/$sample.aligned-reads.fastq
fasta=$output1/$sample.aligned-reads.fasta

samtools bam2fq $bam > $fastq
seqtk seq -A $fastq > $fasta

##############################################################################################################################
#STEP 2: Obtain Ribonucleotide Coordinates

#Location of output files
bed=$output1/$sample.aligned-reads.bed
sam=$output1/$sample.aligned-reads.sam
coordinate_information=$output1/$sample.ribonucleotide-coordinate-information.bed
coordinates_positive_0=$output1/$sample.ribonucleotide-coordinates.positive.0-based.txt
coordinates_negative_0=$output1/$sample.ribonucleotide-coordinates.negative.0-based.txt
coordinates_positive_1=$output1/$sample.ribonucleotide-coordinates.positive.1-based.txt
coordinates_negative_1=$output1/$sample.ribonucleotide-coordinates.negative.1-based.txt
	
#COORDINATES (0-BASED) of SEQUENCING READS

#Covert file from BAM to BED format using BEDtools software
bedtools bamtobed -i $bam > $bed

#Convert file from BAM to SAM format using SAMtools software
samtools view $bam > $sam

#Extract read coordinates, sequences, and strands from BED and SAM files and save it to new file
paste $bed $sam | awk -v "OFS=\t" '{print $1, $2, $3, $16, $6}' > $coordinate_information

#0-BASED COORDINATES OF rNMPs

#Obtain positions of rNMPs (3’ end of each mapped read) for positive strand:
bedtools genomecov -3 -strand + -bg -ibam $bam > $coordinates_positive_0

#Obtain positions of rNMPs (3’ end of each mapped read) for negative strand:
bedtools genomecov -3 -strand - -bg -ibam $bam > $coordinates_negative_0

#1-BASED COORDINATES OF	rNMPs

#Obtain positions of rNMPs (3’ end of each mapped read) for positive strand:
bedtools genomecov -3 -strand + -d -ibam $bam > $coordinates_positive_1

#Remove rows where genome coverage equals 0
awk '$3 != 0' $coordinates_positive_1 > temporary

#Change filename back to original
mv temporary $coordinates_positive_1

#Obtain positions of rNMPs (3’ end of each mapped read) for negative strand:
bedtools genomecov -3 -strand - -d -ibam $bam > $coordinates_negative_1

#Remove rows where genome coverage equals 0
awk '$3 != 0' $coordinates_negative_1 > temporary

#Change filename back to original
mv temporary $coordinates_negative_1

##############################################################################################################################
#STEP 3: Calculate Background Frequencies

#Location of input FASTA file
fasta=$directory/ribose-seq/reference/$subset.fa

#Location of output directory
output2=$directory/ribose-seq/results/Background-Nucleotide-Frequencies

#Create directory for output if it does not already exist
if [[ ! -d $output2 ]];
then
	mkdir -p $output2
fi

#Remove file if it already exists
rm $output2/$reference.$subset.Nucleotide-Frequencies.txt

A_background_count=$(grep -v '>' $fasta | grep -o 'A' - | wc -l)
C_background_count=$(grep -v '>' $fasta | grep -o 'C' - | wc -l)
G_background_count=$(grep -v '>' $fasta | grep -o 'G' - | wc -l)
T_background_count=$(grep -v '>' $fasta | grep -o 'T' - | wc -l)

total_background_count=$(($A_background_count+$C_background_count+$G_background_count+$T_background_count))

A_background_frequency=$(bc <<< "scale = 4; `expr $A_background_count/$total_background_count`")
C_background_frequency=$(bc <<< "scale = 4; `expr $C_background_count/$total_background_count`")
G_background_frequency=$(bc <<< "scale = 4; `expr $G_background_count/$total_background_count`")
T_background_frequency=$(bc <<< "scale = 4; `expr $T_background_count/$total_background_count`")
	
echo "A Background Frequency: $A_background_frequency" >> $output2/$reference.$subset.Nucleotide-Frequencies.txt
echo "C Background Frequency: $C_background_frequency" >> $output2/$reference.$subset.Nucleotide-Frequencies.txt
echo "G Background Frequency: $G_background_frequency" >> $output2/$reference.$subset.Nucleotide-Frequencies.txt
echo "T Background Frequency: $T_background_frequency" >> $output2/$reference.$subset.Nucleotide-Frequencies.txt

##############################################################################################################################
#STEP 4: Calculate Ribonucleotide Frequencies

#Remove file if it already exists
rm $output1/$sample.$reference.$subset.ribonucleotide-frequencies.txt

#Print only ribonucleotides of genome subset to output file
#Whole genome subset
if [[ $subset == "sacCer2" ]];
then
	awk -v "OFS=\t" '{print $4, $5}' $coordinate_information > temporary.txt
#Mitochondria subset
elif [[ $subset == "mitochondria" ]];
then
    	grep 'chrM' $coordinate_information | awk -v "OFS=\t" '{print $4, $5}' - > temporary.txt
#Nuclear subset
elif [[ $subset == "nuclear" ]];
then
	grep -v 'chrM' $coordinate_information | awk -v "OFS=\t" '{print $4, $5}' - > temporary.txt
fi

#Print only ribonucleotides (3' end of read (end for + strand and start for - strand)) to output file

#Print ribonucleotides for positive strands (located at end of sequence)
awk '$2 == "+" {print substr($0,length($0)-2)}' temporary.txt > $output1/$sample.ribonucleotide-list.$subset.txt

#Print ribonucleotides for negative strands (located at beginning of sequence)
awk -v "OFS=\t" '$2 == "-" {print substr($0,0,1), $2}' temporary.txt >> $output1/$sample.ribonucleotide-list.$subset.txt

#Calculate count of "A" ribonucleotides
A_ribonucleotide_count=$(awk '$1 == "A" && $2 == "+" || $1 == "T" && $2 == "-" {print $1, $2}' $output1/$sample.ribonucleotide-list.$subset.txt | wc -l)

#Calculate count of "C"	ribonucleotides
C_ribonucleotide_count=$(awk '$1 == "C" && $2 == "+" || $1 == "G" && $2 == "-" {print $1, $2}' $output1/$sample.ribonucleotide-list.$subset.txt | wc -l)

#Calculate count of "G"	ribonucleotides
G_ribonucleotide_count=$(awk '$1 == "G" && $2 == "+" || $1 == "C" && $2 == "-" {print $1, $2}' $output1/$sample.ribonucleotide-list.$subset.txt | wc -l)

#Calculate count of "U"	ribonucleotides
U_ribonucleotide_count=$(awk '$1 == "T" && $2 == "+" || $1 == "A" && $2 == "-" {print $1, $2}' $output1/$sample.ribonucleotide-list.$subset.txt | wc -l)

total_ribonucleotide_count=$(($A_ribonucleotide_count+$C_ribonucleotide_count+$G_ribonucleotide_count+$U_ribonucleotide_count))

A_ribonucleotide_frequency=$(bc <<< "scale = 4; `expr $A_ribonucleotide_count/$total_ribonucleotide_count`")
C_ribonucleotide_frequency=$(bc <<< "scale = 4; `expr $C_ribonucleotide_count/$total_ribonucleotide_count`")
G_ribonucleotide_frequency=$(bc <<< "scale = 4; `expr $G_ribonucleotide_count/$total_ribonucleotide_count`")
U_ribonucleotide_frequency=$(bc <<< "scale = 4; `expr $U_ribonucleotide_count/$total_ribonucleotide_count`")
		
A_normalized_ribonucleotide_frequency=$(bc <<< "scale = 4; `expr $A_ribonucleotide_frequency/$A_background_frequency`")
C_normalized_ribonucleotide_frequency=$(bc <<< "scale = 4; `expr $C_ribonucleotide_frequency/$C_background_frequency`")
G_normalized_ribonucleotide_frequency=$(bc <<< "scale = 4; `expr $G_ribonucleotide_frequency/$G_background_frequency`")
U_normalized_ribonucleotide_frequency=$(bc <<< "scale = 4; `expr $U_ribonucleotide_frequency/$T_background_frequency`")

echo "$A_normalized_ribonucleotide_frequency $C_normalized_ribonucleotide_frequency $G_normalized_ribonucleotide_frequency \
$U_normalized_ribonucleotide_frequency" | column  > $output1/$sample.$reference.$subset.ribonucleotide-frequencies.txt

rm temporary.txt

##############################################################################################################################
#STEP 5: Obtain coordinates of +/- 100 downstream/upstream nucleotides from rNMPs

#Location of output directory
output3=$directory2/Nucleotides/$subset

#Create directory for output if it does not already exist
if [[ ! -d $output3 ]];
then
    	mkdir -p $output3
fi	

#Location of output files
coordinates=$output1/$sample.ribonucleotide-coordinates.bed

Upstream_Intervals=$output3/$sample.upstream-intervals.bed
Downstream_Intervals=$output3/$sample.downstream-intervals.bed

Upstream_Sequences=$output3/$sample.upstream-sequences.tab
Downstream_Sequences=$output3/$sample.downstream-sequences.tab

temporary1=$output3/temporary.bed
temporary2=$output3/temporary2.bed

#Obtain positions of rNMPs (3’ end of each mapped read)
bedtools genomecov -3 -bg -ibam $bam > $coordinates

#Remove column containing coverage values
awk '!($4="")' $coordinates > $temporary1

#Then, change file back to its original name
mv $temporary1 $coordinates

#Make columns of BED file tab-delimited
sed 's/ \+/\t/g' $coordinates > $temporary2

#Then, change file back to its original name
mv $temporary2 $coordinates

#Obtain coordinates of sacCer2 sequences that are 100 bp upstream of each rNMP position:
bedtools flank -i $coordinates -g $directory/ribose-seq/reference/$reference.bed -l 100 -r 0 > $Upstream_Intervals

#Obtain coordinates of sacCer2 sequences that are 100 bp downstream of each rNMP position:
bedtools flank -i $coordinates -g $directory/ribose-seq/reference/$reference.bed -l 0 -r 100 > $Downstream_Intervals

#Obtain sequences of sacCer2 coordinates from above that are 100 bp upstream of each rNMP position:
bedtools getfasta -fi $directory/ribose-seq/reference/$reference.fa -bed $Upstream_Intervals -tab -fo $Upstream_Sequences

#Obtain sequences of sacCer2 coordinates from above that are 100 bp downstream of each rNMP position:
bedtools getfasta -fi $directory/ribose-seq/reference/$reference.fa -bed $Downstream_Intervals -tab -fo $Downstream_Sequences

##############################################################################################################################
#STEP 6: Output upstream and downstream flanking sequences into tabular format for processing

locations="upstream downstream"

for location in ${locations[@]};
do
	for file in "$output3/$sample.$location.sequences.tab";
	do
		#Location of output directory
		output4=$directory2/Nucleotides/$subset/Columns/$location

		#Create directory for output if it does not already exist
		if [[ ! -d $output4 ]]; then
    			mkdir -p $output4
		fi

		#Create directory for output if it does not already exist
		if [[ ! -d $output4/sequences ]]; then
                	mkdir -p $output4/sequences
        	fi

		#Location of output files
		selection=$output4/sequences/$sample.$location.sequences.$subset.txt
		sequences=$output4/sequences/$sample.$location.sequences.$subset.raw.txt
		columns=$output4/sequences/$sample.$location.sequences.$subset.columns.txt

		if [ $subset == "sacCer2" ];
		then
			cat $file > $selection
		elif [ $subset == "mitochondria" ];
		then
			grep 'chrM' $file > $selection
		elif [ $subset == "nuclear" ];
		then
			grep -v 'chrM' $file > $selection
		fi

		#Print sequences to new file
		awk -v "OFS=\t" '{print $2}' $selection > $sequences

		#Insert tabs between each nucleotide
		cat $sequences | sed 's/.../& /2g;s/./& /g' > $columns

		for i in {1..100};
		do
			awk -v field=$i '{ print $field }' $columns > $output4/$sample.column.$i.$location.$subset.txt
		done
	done
done

##############################################################################################################################
#STEP 7: Calculate frequencies of +/- 100 downstream/upstream nucleotides from ribonucleotides

#Location of output directory
output5=$directory2/Nucleotides/$subset/Raw-Data

#Create directory for output if it does not already exist
if [[ ! -d $output5 ]]; then
    	mkdir -p $output5
fi
		
#Remove old .txt files
rm $output5/*.txt

for location in ${locations[@]};
do
	A_normalized_nucleotide_frequencies=$output5/A_normalized_nucleotide_frequencies.$subset.$location.txt
	C_normalized_nucleotide_frequencies=$output5/C_normalized_nucleotide_frequencies.$subset.$location.txt
	G_normalized_nucleotide_frequencies=$output5/G_normalized_nucleotide_frequencies.$subset.$location.txt
	T_normalized_nucleotide_frequencies=$output5/T_normalized_nucleotide_frequencies.$subset.$location.txt
	Normalized_Nucleotide_Frequencies=$output5/$sample.Normalized_Nucleotide_Frequencies.$subset.$location.txt
		
	input=$directory/ribose-seq/results/$reference/$sample/Nucleotide-Frequencies/Nucleotides/$subset/Columns/$location/$sample*.txt
	
	for file in ${input[@]};
	do
		A_nucleotide_count=$(grep -v '>' $file | grep -o 'A' - | wc -l)
		C_nucleotide_count=$(grep -v '>' $file | grep -o 'C' - | wc -l)
		G_nucleotide_count=$(grep -v '>' $file | grep -o 'G' - | wc -l)
		T_nucleotide_count=$(grep -v '>' $file | grep -o 'T' - | wc -l)

		total_nucleotide_count=$(($A_nucleotide_count+$C_nucleotide_count+$G_nucleotide_count+$T_nucleotide_count))
	
		A_nucleotide_frequency=$(bc <<< "scale = 4; `expr $A_nucleotide_count/$total_nucleotide_count`")
		C_nucleotide_frequency=$(bc <<< "scale = 4; `expr $C_nucleotide_count/$total_nucleotide_count`")
		G_nucleotide_frequency=$(bc <<< "scale = 4; `expr $G_nucleotide_count/$total_nucleotide_count`")
		T_nucleotide_frequency=$(bc <<< "scale = 4; `expr $T_nucleotide_count/$total_nucleotide_count`")

		A_normalized_nucleotide_frequency=$(bc <<< "scale = 4; `expr $A_nucleotide_frequency/$A_background_frequency`")
        	C_normalized_nucleotide_frequency=$(bc <<< "scale = 4; `expr $C_nucleotide_frequency/$C_background_frequency`")
        	G_normalized_nucleotide_frequency=$(bc <<< "scale = 4; `expr $G_nucleotide_frequency/$G_background_frequency`")
        	T_normalized_nucleotide_frequency=$(bc <<< "scale = 4; `expr $T_nucleotide_frequency/$T_background_frequency`")

		echo $A_normalized_nucleotide_frequency >> $A_normalized_nucleotide_frequencies
		echo $C_normalized_nucleotide_frequency >> $C_normalized_nucleotide_frequencies
		echo $G_normalized_nucleotide_frequency >> $G_normalized_nucleotide_frequencies
		echo $T_normalized_nucleotide_frequency >> $T_normalized_nucleotide_frequencies

		if [ -e "$Normalized_Nucleotide_Frequencies" ]; then
    			rm $Normalized_Nucleotide_Frequencies
		fi

		paste $A_normalized_nucleotide_frequencies $C_normalized_nucleotide_frequencies \
		$G_normalized_nucleotide_frequencies $T_normalized_nucleotide_frequencies >> \
		$Normalized_Nucleotide_Frequencies
	done
done

##############################################################################################################################
#STEP 8: Create .txt file containing the output nucleotide frequencies data values for plotting

#Location of output directory
output6=$directory2/Datasets/$subset

#Create directory for output if it does not already exist
if [[ ! -d $output6 ]]; then
    	mkdir -p $output6
fi

#Remove old .txt files
rm $output6/*.txt

#Print values -100 to 100
seq -100 1 100 > temporary1.txt

#Combine upstream and downstream normalized nucleotide frequency files and ribonucleotide frequency files
cat $output5/$sample.Normalized_Nucleotide_Frequencies.$subset.upstream.txt $output1/$sample.$reference.$subset.ribonucleotide-frequencies.txt \
$output5/$sample.Normalized_Nucleotide_Frequencies.$subset.downstream.txt >> temporary2.txt

dataset=$output6/$sample.Nucleotide_Frequency_Dataset.$subset.txt

#Merge two files into final .txt file
paste temporary1.txt temporary2.txt > temporary3.txt

#Add Header to beginning of .txt file 
echo "Position A C G U/T" | awk '{print $1,"\t",$2,"\t",$3,"\t",$4,"\t",$5}' | cat - temporary3.txt > temp && mv temp temporary3.txt

#Make sure data values are arranged in columns
column -t temporary3.txt > $dataset

rm temporary1.txt temporary2.txt temporary3.txt
