#!/bin/bash

# REQUIRES:
# Discord.sh - https://github.com/ChaoticWeg/discord.sh
# jq - Used for JSON parsing
# curl - Interacting with the GW2 API and sending payload to Discord

# Script to output the world populations.
# Will post to Discord channel.

# Discord
hook=

# Files to be used for comparisons
last_pop_file=/usr/local/bin/pops/last.txt
new_pop_file=/usr/local/bin/pops/new.txt

# Get current worlds and populations
curl --silent https://api.guildwars2.com/v2/worlds?ids=all | jq '.[] | select(.id >= 2000)' --compact-output | awk -F '"' '{print $6"-"$10}' | sort > $new_pop_file

# Add some colour
sed -i 's#-Full#-:red_square: Full##g' $new_pop_file
sed -i 's#-VeryHigh#-:orange_square: Very High##g' $new_pop_file
sed -i 's#-High#-:yellow_square: High##g' $new_pop_file
sed -i 's#-Medium#-:green_square: Medium##g' $new_pop_file
sed -i 's#-Low#-:blue_square: Low##g' $new_pop_file

# Check if first run
# There will be no existing file
if [ -s $last_pop_file ]
then
        # Ensure there are differences
        if [ $(diff --report-identical-files $last_pop_file $new_pop_file | grep --count identical) -gt 0 ]
        then
                # Files are the same and no changes
                exit 0
        fi

        # Get name of worlds with new populations
        new_list+=$(comm -23 $last_pop_file $new_pop_file | awk -F '-' '{print $1}')

        # Loop through the names and get old and new populations
        while read pop
        do
                world=$pop
                old_pop=$(grep --fixed-strings "$pop" $last_pop_file | awk -F '-' '{print $2}')
                new_pop=$(grep --fixed-strings "$pop" $new_pop_file | awk -F '-' '{print $2}')
                text+="\n$world -- $old_pop >  $new_pop"
        done <<< $new_list

else
        text="\nNo data to process.\nThis is either the first run of the script or an error has ocurred."
fi

# Overwrite the population file
mv --force $new_pop_file $last_pop_file

# Post to Discord
/usr/local/bin/discord.sh --webhook-url="$hook" --title="Population update" --description="$text" --timestamp

exit 0
