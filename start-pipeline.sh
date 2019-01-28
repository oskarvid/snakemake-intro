docker run \
--rm \
-ti \
-v $(pwd):/data \
-w /data \
oskarv/snakemake \
snakemake -j \
--use-conda
