#!/usr/bin/bash

if [[ -z $1 ]]; then
	echo ""
elif [[ $1 == "--use-conda" ]]; then
	CONDA="$1"
elif [[ ! -z $1 ]]; then
	echo "Option '$1' is not recognized, only --use-conda is valid"
	exit
fi

docker run \
--rm \
-ti \
-v $(pwd):/data \
-w /data \
oskarv/smkintro \
snakemake -j ${CONDA}
