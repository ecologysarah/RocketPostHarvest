#Pete Kille's script
#Load CharlieCloud and start interactive job
module load charliecloud/0.22
srun -c 8 --mem 32G -p mammoth --pty /mnt/scratch/nodelete/CharlieCloud/v0.22-scripts/CharlieCloud_trinityrnaseq_2.12.0.interactive.job

# Create gene to trans map file if it does not exist
/usr/local/bin/util/support_scripts/get_Trinity_gene_to_trans_map.pl /mnt/scratch/sbi9srj/Lama/4C-evigene/Diplotaxis_tenuifolia_okay18.fasta > /mnt/scratch/sbi9srj/Lama/4C-evigene/Diplotaxis_tenuifolia_evigene.gene_trans_map

# Combined abundance estimates and apply threshold
# Use 'isoforms' if you want both gene and isform outputs
/usr/local/bin/util/abundance_estimates_to_matrix.pl \
	--gene_trans_map /mnt/scratch/sbi9srj/Lama/4C-evigene/Diplotaxis_tenuifolia_evigene.gene_trans_map \
	--name_sample_by_basedir \
	--est_method RSEM \
	/mnt/scratch/sbi9srj/Lama/5-RSEM/NSP-r1_S7_merge_/RSEM.isoforms.results \
	/mnt/scratch/sbi9srj/Lama/5-RSEM/SNP-r3_S9_merge_/RSEM.isoforms.results \
	/mnt/scratch/sbi9srj/Lama/5-RSEM/S-r2_S5_merge_/RSEM.isoforms.results \
	/mnt/scratch/sbi9srj/Lama/5-RSEM/NSP-r2_S8_merge_/RSEM.isoforms.results \
	/mnt/scratch/sbi9srj/Lama/5-RSEM/SP-r1_S10_merge_/RSEM.isoforms.results \
	/mnt/scratch/sbi9srj/Lama/5-RSEM/S-r3_S6_merge_/RSEM.isoforms.results \
	/mnt/scratch/sbi9srj/Lama/5-RSEM/NS-r1_S1_merge_/RSEM.isoforms.results \
	/mnt/scratch/sbi9srj/Lama/5-RSEM/SP-r2_S11_merge_/RSEM.isoforms.results \
	/mnt/scratch/sbi9srj/Lama/5-RSEM/NS-r2_S2_merge_/RSEM.isoforms.results \
	/mnt/scratch/sbi9srj/Lama/5-RSEM/SP-r3_S12_merge_/RSEM.isoforms.results \
	/mnt/scratch/sbi9srj/Lama/5-RSEM/NS-r3_S3_merge_/RSEM.isoforms.results \
	/mnt/scratch/sbi9srj/Lama/5-RSEM/S-r1_S4_merge_/RSEM.isoforms.results \
	--out_prefix Dip-ten_RSEM
 
$TRINITY_HOME/util/misc/count_matrix_features_given_MIN_TPM_threshold.pl  Dip-ten_RSEM.gene.TPM.not_cross_norm | tee Dip-ten_RSEM.qgenes_matrix.TPM.not_cross_

# Perform sample comparisons
$TRINITY_HOME/Analysis/DifferentialExpression/PtR --matrix Dip-ten_RSEM.gene.counts.matrix --samples /mnt/scratch/sbi9srj/Lama/samples.txt --CPM --log2 --compare_replicates
 
$TRINITY_HOME/Analysis/DifferentialExpression/PtR --matrix Dip-ten_RSEM.gene.counts.matrix -s /mnt/scratch/sbi9srj/Lama/samples.txt --log2 --sample_cor_matrix
 
$TRINITY_HOME/Analysis/DifferentialExpression/PtR --matrix Dip-ten_RSEM.gene.counts.matrix -s /mnt/scratch/sbi9srj/Lama/samples.txt --log2 --prin_comp 3

#Differential analysis
$TRINITY_HOME/Analysis/DifferentialExpression/run_DE_analysis.pl --matrix Dip-ten_RSEM.gene.counts.matrix --samples_file /mnt/scratch/sbi9srj/Lama/samples.txt --method edgeR --output edgeR_results
 
$TRINITY_HOME/Analysis/DifferentialExpression/analyze_diff_expr.pl --matrix Dip-ten_RSEM.gene.TMM.EXPR.matrix -P 1e-3 -C 1.4 --samples /mnt/scratch/sbi9srj/Lama/samples.txt
