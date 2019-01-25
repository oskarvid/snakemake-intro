docker run \
--rm \
-ti \
-v $REFERENCES:/references \
-v $(pwd):/data \
-w /data \
oskarv/snakemake \
snakemake -j \
--use-conda \
--use-singularity
