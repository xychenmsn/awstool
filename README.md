# AWSTool

AWSTool is a collection of command-line tools designed to enhance your productivity in AWS CloudShell.
The frst version only has a tail_aws_logs which allows tail of aws cloudwatch logs.

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

The `tail_aws_logs` function allows you to tail AWS CloudWatch logs directly from your command line, offering various options for filtering and customization. Here is how you can use it:

- To tail logs from a specific log group:

```bash
tail_aws_logs -g <log_group_name>
```

- To include additional filtering and customization options:

```bash
tail_aws_logs -g <log_group_name> -s <stream_pattern> -h <history_minutes> -t <timezone> -p <poll_interval_seconds>
```

**Options:**

- `--loggroup, -g`: The name of the CloudWatch Log Group (**required**).
- `--stream, -s`: The pattern of stream name within the Log Group (optional).
- `--history, -h`: The history window in minutes to fetch logs from (optional, default is 1).
- `--timezone, -t`: The timezone to display timestamps in (optional, default is America/New_York).
- `--poll-interval, -p`: The interval in seconds between log fetches (optional, default is 5).
- `--help`: Show usage page.
**Examples:**

- Tail logs from the "billing-qa" log group, filtering by the "payment" stream, with a history window of 10 minutes, in the PST timezone, polling every 5 seconds:

```bash
tail_aws_logs --loggroup "billing-qa" --stream "payment" --history 10 --timezone "America/Los_Angeles" --poll-interval 5
```

- Tail logs from the "billing-qa" with a history of 5 minutes, polling every 10 seconds:

```bash
tail_aws_logs -g billing-qa -h 5 -p 10 | grep "invoice"
```

If you would want the logs to use a default timezone other than EST, you could run:

```bash
set_tz
```

For more information on each command and additional options, refer to the individual tool documentation within the `src` folder.
