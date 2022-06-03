#!/bin/bash

array=( bh bic cycle_score gal normal reviews_scored_by_weakness )

for i in "${array[@]}"
do
  echo "ejecutando tests con application.$i.yml"
	CONFIG_TYPE=$i rails test
done
