#!/bin/bash

array=( bh bic cycle_score gal normal reviews_scored_by_weakness )

for i in "${array[@]}"
do
  echo "ejecutando tests con application.$i.yml"
  CONFIG_TYPE=$i rails test
done

mv config/application.yml config/application.yml.temp
cp config/application.yml.example config/application.yml
echo "ejecutando tests con application.yml.example"
rails test
rm config/application.yml
mv config/application.yml.temp config/application.yml
