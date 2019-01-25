# Creates an array ranging from 1 to 3
NUMBERARRAY = range(1, 4, 1)

rule all:
	input:
		expand("inputs/input-file-{file}", file=NUMBERARRAY),
		expand("outputs/compared-files-{file}", file=NUMBERARRAY),
		expand("inputs/germline-{file}.vcf", file=NUMBERARRAY),
		expand("outputs/bcftools-stats-{file}.output", file=NUMBERARRAY),
		"outputs/bcftools-stats.output",

rule BasicRule:
	input:
		"inputs/basic-file",
	output:
		"outputs/modified-basic-file",
	shell:
		"cp {input} {output}"

rule ParallelProcessingRule:
	input:
		"inputs/input-file-{file}",
	output:
		"outputs/first-rule-output-file-{file}",
	shell:
		"cp {input} {output}"

rule MultipleInputsToOneToolRule:
	input:
		expand("outputs/first-rule-output-file-{file}", file=NUMBERARRAY),
	output:
		"outputs/combined-output-file.gz",
	shell:
		"gzip -c {input} > {output}"

rule MoreThanOneFileAsInputRule:
	input:
		first = "outputs/modified-basic-file",
		second = "outputs/first-rule-output-file-{file}",
	output:
		"outputs/compared-files-{file}",
	shell:
		"comm -12 <(sort {input.first}) <(sort {input.second}) > {output}"

rule CondaInstallBCFToolsRule:
	input:
		"inputs/germline.vcf",
	output:
		"outputs/germline.bcf",
	conda:
		"bcftools.yaml"
	shell:
		"bcftools --version && echo 'This is a placeholder' && cat {input} > {output}"

rule CondaShowBCFToolsVersionWithParamsRule:
	input:
		"outputs/germline.bcf",
	output:
		"outputs/germline.xcf",
	conda:
		"bcftools.yaml"
	params:
		"--version"
	priority: 3
	shell:
		"bcftools {params} && echo 'This is a placeholder' && cat {input} > {output}"

rule CondaBCFToolsMultipleParamsRule:
	input:
		"inputs/germline.vcf",
	output:
		"outputs/bcftools-stats.output",
	conda:
		"bcftools.yaml",
	params:
		stats = "stats",
		verbose = "-v",
	priority: 2
	shell:
		"bcftools {params.stats} {params.verbose} {input} > {output}"

rule CondaBCFToolsMultipleThreadsRule:
	input:
		"inputs/germline-{file}.vcf",
	output:
		"outputs/bcftools-stats-{file}.output",
	conda:
		"bcftools.yaml",
	params:
		stats = "stats",
		verbose = "-v",
	threads:
		12
	priority: 1
	shell:
		"bcftools {params.stats} {params.verbose} {input} > {output}"

