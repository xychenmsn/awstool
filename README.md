Certainly, let's ensure the README.md content is correctly formatted as a complete markdown source file for copying:

```markdown
# AWSTool

AWSTool is a collection of command-line tools designed to enhance your productivity in AWS CloudShell or other AWS bash environments. These tools offer various functionalities, including tailing AWS CloudWatch logs, setting time zones, and more, directly from your command line.

## Installation

You can install AWSTool in your environment in two ways:

### Method 1: Using Curl

Run the following command to automatically download and install AWSTool:

```bash
curl -o- https://raw.githubusercontent.com/xychenmsn/awstool/main/install_awstool.sh | bash
```

### Method 2: Manual Download

1. Download `awstool.sh` from the GitHub repository to your home directory (`~/`).
2. Add the following line to your `.bashrc` to source the tool:

```bash
source ~/awstool.sh
```

After installation, restart your terminal or source your `.bashrc` file to apply the changes:

```bash
source ~/.bashrc
```

## Usage

### Tail AWS Logs

`tail_aws_logs` allows you to tail AWS CloudWatch logs directly from your command line. Here are a few examples of how to use it:

- Tail logs from a specific log group and app:

```bash
tail_aws_logs <log_group_name> <app_name>
```

- Tail logs from a specific log group and app, setting the history window and time zone:

```bash
tail_aws_logs <log_group_name> <app_name> <history_minutes> [<timezone>]
```

For more information on each command and additional options, refer to the individual tool documentation within the `src` folder.
```

Please replace `https://raw.githubusercontent.com/yourusername/awstool/main/install_awstool.sh` with the actual URL to your `install_awstool.sh` script on GitHub, and adjust the `yourusername` part to match your GitHub username.