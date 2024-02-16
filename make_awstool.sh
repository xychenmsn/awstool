### make_awstool.sh

# Combine all source files into awstool.sh
echo "#!/bin/bash" > awstool.sh
echo "" >> awstool.sh

# Concatenate each script in src into awstool.sh
for script in src/*.sh; do
    echo "# $(basename "$script")" >> awstool.sh
    cat "$script" >> awstool.sh
    echo "" >> awstool.sh
done

echo "AWSTool has been compiled into awstool.sh."