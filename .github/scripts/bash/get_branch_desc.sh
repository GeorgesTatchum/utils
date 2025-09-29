#!/bin/bash

echo "# Branches du projet" > BRANCHES.md
echo "" >> BRANCHES.md

for branch in $(git branch -r | grep -v '->'); do
    branch_name=$(echo $branch | sed 's#origin/##')
    desc=$(git log origin/$branch_name --grep="^desc-$branch_name:" --pretty=format:"%s" -1)
    if [ -z "$desc" ]; then
        desc="(Pas de description)"
    else
        desc=$(echo $desc | sed "s/^desc-$branch_name: //")
    fi
    echo "- **$branch_name** : $desc" >> BRANCHES.md
done
