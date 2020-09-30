docker run \
--rm \
-ti \
-v $(pwd):/data \
-w /data \
snakemake/snakemake \
snakemake -j \
--use-conda
