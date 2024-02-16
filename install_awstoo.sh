#!/bin/bash

# Download awstool.sh from the GitHub repository
curl -o ~/awstool.sh https://raw.githubusercontent.com/yourusername/awstool/main/awstool.sh

# Make it executable
chmod +x ~/awstool.sh

# Append source command to .bashrc if not already present
if ! grep -q "source ~/awstool.sh" ~/.bashrc; then
    echo "source ~/awstool.sh" >> ~/.bashrc
    echo "AWSTool installed successfully. Please restart your terminal or run 'source ~/.bashrc' to use it."
else
    echo "AWSTool is already installed."
fi
