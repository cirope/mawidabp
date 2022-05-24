#!/bin/bash

array=( bh bic cycle_score gal normal reviews_scored_by_weakness )

for i in "${array[@]}"
do
	CONFIG_TYPE=$i rails test
done