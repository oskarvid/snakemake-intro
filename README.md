# Short intro to snakemake
This is a very short intro that should cover the absolute basics and give some inspiration about what's possible beyond the basics.  
You should be aware that there's probably ways of doing this more elegantly, but this will run 100% and get you started. The [official snakemake documentation](https://snakemake.readthedocs.io/en/stable/) has more information about everything I've covered here.

NB. Just pretend like it's doing something useful, much of it is simple placeholding to demonstrate the principles of the code, the input files and actual code that is executed is nonsensical at times.

![snakemake-dag](https://raw.githubusercontent.com/oskarvid/snakemake-intro/master/dag.png)

## Dependencies
1. Docker - [Installation instructions](https://docs.docker.com/install/)  
2. oskarv/snakemake docker image - `sudo docker pull oskarv/snakemake`
3. graphviz - Optional, necessary for creating nice graphs of the workflow like the one above.

You can run the workflow with my docker image. You can also run the workflow with `Snakemake` installed locally, I haven't tested that so I don't know what the dependencies are. If this is your first introduction to Snakemake or docker it's time to start learning!

## How to run the workflow
Run the start script like so: `./start-pipeline.sh`.  
This will automatically download the docker image if you haven't downloaded it already.

# Explaining the basics of the rules in the Snakefile
## A very very basic rule
The following rule is the most basic rule you can make, it has an input file, an output file and a shell command.
```python
rule BasicRule: # rule name
	input: # input directive
		"inputs/basic-file", # input file
	output: # output directive
		"outputs/modified-basic-file", # output file
	shell: # shell directive
		"cp {input} {output}" # shell command
```
The only magic that happens is that instead of writing `cp inputs/basic-file outputs/modified-basic-file` we use the `{input}` and `{output}` snakemake representations of the file paths that are specified under the `input` and `output` directives.

## Creating the `all` rule
Every Snakefile needs an `all` rule. Without an input file to the `all` rule the workflow won't run. If you have only one tool rule, the output from this tool rule is the input to the `all` rule. Given our very very basic tool rule above, a complete minimal Snakefile would look like this:
```python
rule all:
	input:
		"outputs/modified-basic-file",

rule BasicRule:
	input:
		"inputs/basic-file",
	output:
		"outputs/modified-basic-file",
	shell:
		"cp {input} {output}"
```
To run the workflow you need to execute `snakemake` from the directory where your Snakefile is located, and given that the input file exists, snakemake will create the output directory when it executes the code in the `shell` directive and copy the input file to the file specified in the `{output}` directive.

## Defining a variable in a tool rule
Let's use the following rule to explain how to define a variable inside a tool rule:  
```python
NUMBERARRAY = range(1, 4, 1)
rule MultipleInputsToOneToolRule:
	input:
		expand("outputs/first-rule-output-file-{file}", file=NUMBERARRAY),
	output:
		"outputs/combined-output-file.gz",
	shell:
		"gzip -c {input} > {output}"
```
A tool rule doesn't know what the variable `{file}` means unless you define it somehow, we use `expand("outputs/first-rule-output-file-{file}", file=NUMBERARRAY)` to define the `{file}` variable. In this rule `{file}` is defined in the tool rule, but depending on the desired behavior `{file}` can also be defined in the `all` rule as explained below.  
Defining the variable in a tool rule will supply all input files at once. Continue reading to get an explanation of when to define a variable in a tool rule or in the `all` rule.

## Defining a variable in the `all` rule
A variable is defined in the same way in the `all` rule as it is done in a tool rule, _i.e_ with `expand()` as shown in the example below.
```python
NUMBERARRAY = range(1, 4, 1)
rule all:
	input:
		expand("inputs/input-file-{file}", file=NUMBERARRAY),
```
Defining a variable in the `all` rule is used to make tools run in parallel, taking one input file per spawned process.

## When to define a variable in the `all` rule or a tool rule
1. Defining a variable in the `all` rule as shown below will run the rule once per input file. Snakemake can do this in parallel if you enable it by using the `-j` flag when you start the workflow.  

```python
NUMBERARRAY = range(1, 4, 1)
rule all:
	input:
		expand("inputs/input-file-{file}", file=NUMBERARRAY),

rule ParallelProcessingRule:
	input:
		"inputs/input-file-{file}",
	output:
		"outputs/first-rule-output-file-{file}",
	shell:
		"cp {input} {output}"
```
2. Defining a variable in a tool rule will use the variable to expand the file path and supply all input files _at once_. In the `MultipleInputsToOneToolRule` rule example above, the rule will take all files that match the pattern `outputs/first-rule-output-file-{1,2,3}` and run `gzip -c` to create a .gz archive of all input files.  

## Using two or more input or output files for a rule
Some tools take two or more input files as shown in the example below.
```python
rule MoreThanOneFileAsInputRule:
	input:
		first = "outputs/modified-basic-file",
		second = "outputs/first-rule-output-file-{file}",
	output:
		"outputs/compared-files-{file}",
	shell:
		"comm -12 <(sort {input.first}) <(sort {input.second}) > {output}"
```
The input files are selected by writing `{input.first}` and `{input.second}`. You can have multiple `{output}` files as well, just use the same syntax as shown in the `input` directive. This particular rule will compare each `outputs/first-rule-output-file-*` file with the `outputs/modified-basic-file` file and output the lines that are the same into the `outputs/compared-files-{file}` file. 

## Installing exact tool versions with Conda
Tools can be installed in a virtual environment automatically by using `conda` as shown in the example below.
```python
rule CondaInstallBCFToolsRule:
	input:
		"inputs/germline.vcf",
	conda:
		"bcftools.yaml"
	output:
		"outputs/germline.bcf",
	shell:
		"bcftools --version && echo 'This is a placeholder' && cat {input} > {output}"
```
It is the `conda:` directive that is responsible for this magic, and as shown it is necessary to define the tool version etc in a yaml file as shown below.
```yaml
name: bcftools
channels:
  - bioconda
  - conda-forge
  - defaults
dependencies:
  - bcftools=1.9
```
The tool will get installed in a separate virtual environment.

## Using the parameter directive
Sometimes it is desireable to use variables or config files* to define parameters, or to just simply make the `shell` directive code cleaner if one so wishes. The syntax is the same as for `{input}` and `{output}`, either just write `{params}` or `{params.something}` if you have more than one parameter like in the example below.
\*Config files are not covered in this intro, check out the official documentation in the link above for more information.

```python
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
```

## Limiting the number of parallel processes
Sometimes you have multiple files that need to be processed, but if you have limited compute resources you may only be able to process one file at a time. To limit the number of spawned processes you can use the `{threads}` directive. This will trick Snakemake into thinking that the rule will use 16 threads as in the example below.
```python
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
	threads: 16
	priority: 1
	shell:
		"bcftools {params.stats} {params.verbose} {input} > {output}"
```
Let's assume our pretend server has 16 threads, Snakemake will assume that all threads are now in use and therefore only one process can be spawned. Even if the job in reality only uses one thread this can be useful if the job consumes too much RAM when you run two or more jobs at a time.

## Visualizing the workflow with a directed acyclical graph (dag)
It is often very enlightening to get a graphical representation of the different workflow steps and how they relate to each other. Fortunately Snakemake has a built in way of producing what is called a directed acyclical graph, or dag for short. This is dependent on having `graphviz` installed. The basic command is `snakemake --dag` to just produce a raw "dot" output to the terminal. If you want to automagically create the graph you run `snakemake --dag | dot -Tsvg > dag.svg` after you have installed `graphviz`.  
Here is an example of a graph I created for another workflow: https://raw.githubusercontent.com/neicnordic/GRSworkflow/optimized/.GRSworkflowDAG.png  
This workflow wasn't written in Snakemake though, I simply created a logical representation of the steps in Snakemake only so I could make this graph.  
Here's another graph from a germline variant calling pipeline: https://github.com/oskarvid/snakemake_germline/blob/master/dag.png

## Further reading
Using the examples in this short introduction should get you started, make sure to hone your Google skills to figure out what's wrong or how to do things better when you're building your first Snakemake workflow. The official documentation is always a good place to look.  
You can take a look at our [germline variant calling workflow](https://github.com/elixir-no-nels/snakemake_germline) built in Snakemake for a real life example of what can be achieved with Snakemake.  
