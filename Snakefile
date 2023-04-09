

################# CONVERT .GFF3 TO GTF AND MOVE AGAT LOGFILE ###########
rule make_gtf:
    input:
        script = "scripts/zsh/make_gtf.zsh",
        gff = "raw_files/annotations/thev_from_NCBI.gff3"
    output:
        "raw_files/annotations/thev_from_NCBI.gtf",
        "raw_files/annotations/thev_from_NCBI.agat.log"
    shell:
        "{input.script}"

################### EXTRACT SPLICE-SITES ####################
rule extract_splice_site:
    input:
        script = "scripts/zsh/extract_ss.zsh",
        gtf = "raw_files/annotations/thev_from_NCBI.gtf"
    output:
        "raw_files/annotations/thev_predicted_genes.ss"
    shell:
        "{input.script}"

################### EXTRACT EXONS ####################
rule extract_exons:
    input:
        script = "scripts/zsh/extract_exons.zsh",
        gtf = "raw_files/annotations/thev_from_NCBI.gtf"
    output:
        "raw_files/annotations/thev_predicted_genes.exons"
    shell:
        "{input.script}"

#################### BUILD THEV GENOMIC INDEX FOR MAPPING WITH HISAT2 ######
rule build_genome_index:
    input:
        script = "scripts/zsh/build_genome_index.zsh",
        ss = "raw_files/annotations/thev_predicted_genes.ss",
        exon = "raw_files/annotations/thev_predicted_genes.exons",
        genome = "raw_files/genome_file/AY849321.1.fa"
    output:
        expand("raw_files/thevgenome_index/thev_tran.{n}.ht2", \
        n = [1, 2, 3, 4, 5, 6, 7,8])
    shell:
        "{input.script}"

#################### MAP READS TO THEV GENOME WITH HISAT2 #############
rule map_sort_to_bam:
    input:
        script = "scripts/zsh/map_sort_to_bam.zsh",
        seqidx = expand("raw_files/thevgenome_index/thev_tran.{n}.ht2", \
        n = [1, 2, 3, 4, 5, 6, 7,8]),
        fordata = expand("trimmedReads/forwardTrims/LCS9132_I_{tp}hrsS{rep}_Clean_Data1_val_1.fq.gz", \
        tp = [72, 24, 4], rep = [1, 2, 3]),
        for12 = expand("trimmedReads/forwardTrims/LCS9132_I_12hrsS{rep}_Clean_Data1_val_1.fq.gz", \ 
        rep = [1, 3] ),
        revdata = expand("trimmedReads/reverseTrims/LCS9132_I_{tp}hrsS{rep}_Clean_Data2_val_2.fq.gz", \
        tp = [72, 24, 4], rep = [1, 2, 3]),
        rev12 = expand("trimmedReads/reverseTrims/LCS9132_I_12hrsS{rep}_Clean_Data2_val_2.fq.gz", \
        rep = [1, 3])
    output:
        expand("results/hisat2/thev_sorted_{time}hrsS{rep}.bam", \
        time = ["72", "24", "4"], rep = ["1", "2", "3"]),
        expand("results/hisat2/thev_sorted_12hrsS{rep}.bam", \
        rep = ["1", "3"])
    shell:
        "{input.script}"

#################### INDEX ALL SORTED .BAM FILES ##################
rule index_bam_files:
    input:
        script = "scripts/zsh/index.zsh",
        bam = expand("results/hisat2/thev_sorted_{time}hrsS{rep}.bam", \
        time = ["72", "24", "4"], rep = ["1", "2", "3"]),
        bam12 = expand("results/hisat2/thev_sorted_12hrsS{rep}.bam", \
        rep = ["1", "3"])
    output:
        expand("results/hisat2/thev_sorted_{time}hrsS{rep}.bam.bai", \
        time = ["72", "24", "4"], rep = ["1", "2", "3"]),
        expand("results/hisat2/thev_sorted_12hrsS{rep}.bam.bai", \
        rep = ["1", "3"])
    shell:
        "{input.script}"

#################### CONSTRUCT TRANSCRIPTS WITH STRINGTIE ##############
rule make_transcripts:
    input:
        script = "scripts/zsh/assemble_transcripts.zsh",
        gtf = "raw_files/annotations/thev_from_NCBI.gtf",
        bam = expand("results/hisat2/thev_sorted_{time}hrsS{rep}.bam", \
        time = ["72", "24", "4"], rep = ["1", "2", "3"]),
        bam12 = expand("results/hisat2/thev_sorted_12hrsS{rep}.bam", \
        rep = ["1", "3"])
    output:
        expand("results/stringtie/thev_{time}hrsS{rep}.gtf", \
        time = [4, 24, 72], rep = [1, 2, 3]),
        expand("results/stringtie/thev_12hrsS{rep}.gtf", \
        rep = [1, 3])
    shell:
        "{input.script}"

#################### MERGE ALL GTF FILES #####################
rule merge_gtfs:
    input:
        expand("results/stringtie/thev_{time}hrsS{rep}.gtf", \
        time = [4, 24, 72], rep = [1, 2, 3]),
        expand("results/stringtie/thev_12hrsS{rep}.gtf", \
        rep = [1, 3])
    output:
        "results/stringtie/all_merged.gtf"
    shell:
        "cat {input} > {output}"

##################### FILTER FOR REAL TRANSCRIPTS (REMOVE PREDICTED ORFs) ######
rule remove_duplicate_transcripts:
    input:
        r_script = "scripts/r/filter_real_transcripts.R",
        all_gtf = "results/stringtie/all_merged.gtf"
    output:
        "results/stringtie/all_real_transcripts_merged.gtf"
    shell:
        "{input.r_script}"


#################### BULK MAP READS ##########
rule bulk_map_sort_to_bam:
    input:
        script = "scripts/zsh/bulk_map_sort_to_bam.zsh",
        seqidx = expand("raw_files/thevgenome_index/thev_tran.{n}.ht2", \
        n = [1, 2, 3, 4, 5, 6, 7,8]),
        fordata = expand("trimmedReads/forwardTrims/LCS9132_I_{tp}hrsS{rep}_Clean_Data1_val_1.fq.gz", \
        tp = [72, 24, 4], rep = [1, 2, 3]),
        for12 = expand("trimmedReads/forwardTrims/LCS9132_I_12hrsS{rep}_Clean_Data1_val_1.fq.gz", \ 
        rep = [1, 3] ),
        revdata = expand("trimmedReads/reverseTrims/LCS9132_I_{tp}hrsS{rep}_Clean_Data2_val_2.fq.gz", \
        tp = [72, 24, 4], rep = [1, 2, 3]),
        rev12 = expand("trimmedReads/reverseTrims/LCS9132_I_12hrsS{rep}_Clean_Data2_val_2.fq.gz", \
        rep = [1, 3])
    output:
        expand("results/hisat2/bulk/sortedTHEV_{time}hrsSamples.bam", \
        time = [4, 12, 24, 72])
    shell:
        "{input.script}"

#################### BULK COVERAGE #########
rule bulk_coverage:
    input:
        script = "scripts/zsh/bulk_coverage.zsh",
        bam = expand("results/hisat2/bulk/sortedTHEV_{time}hrsSamples.bam", \
        time = [4, 12, 24, 72])
    output:
        "results/hisat2/coverage/bulk_coverage.txt"
    shell:
        "{input.script}"

#################### BULK DEPTH ############
rule bulk_depth:
    input:
        script = "scripts/zsh/bulk_depth.zsh",
        bam = expand("results/hisat2/bulk/sortedTHEV_{time}hrsSamples.bam", \
        time = [4, 12, 24, 72])
    output:
        expand("results/hisat2/coverage/thev_{time}hrsdepth.txt", \
        time = [4, 12, 24, 72])
    shell:
        "{input.script}"

#################### MAKE FIGURES FOR DEPTH/COVERAGE ############
rule make_coverage_figures:
    input:
        r_script1 = "scripts/r/thev_cov_depth.R",
        r_script2 = "scripts/r/thev_genomic_map.R",
        bedfile = "raw_files/annotations/THEVannotated_genesOnly.bed",
        depth = expand("results/hisat2/coverage/thev_{time}hrsdepth.txt", \
        time = [4, 12, 24, 72]),
        coverage = "results/hisat2/coverage/bulk_coverage.txt"
    output:
        expand("results/r/figures/depth_{time}hrs.pdf", \
        time = [4, 12, 24, 72]),
        expand("results/r/figures/{plotkind}_alltimes.pdf", \
        plotkind = ["patch", "overlay", "correlate"])
    shell:
       "{input.r_script1}"

############# RUN ENTIRE SCRIPT RULE ##############
rule run_pipeline:
    input:
        rules.make_gtf.output,
        rules.extract_splice_site.output,
        rules.extract_exons.output,
        rules.build_genome_index.output,
        rules.map_sort_to_bam.output,
        rules.index_bam_files.output,
        rules.make_transcripts.output,
        rules.merge_gtfs.output,
        rules.remove_duplicate_transcripts.output,
        rules.bulk_map_sort_to_bam.output,
        rules.bulk_coverage.output,
        rules.bulk_depth.output,
        rules.make_coverage_figures.output
        