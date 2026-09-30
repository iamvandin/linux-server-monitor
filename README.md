## Automated Monitoring

The monitoring script can be scheduled using Linux Cron.

Example:

```cron
*/5 * * * * /path/to/monitor.sh >> /path/to/logs/monitoring.log 2>&1

## Alerting

The monitoring tool checks configured thresholds for:

- CPU usage
- Memory usage
- Disk usage

When a threshold is exceeded, an alert is written to:

```text
logs/alerts.log

## Alert States

The monitoring tool uses three states:

| State | Meaning | Exit Code |
|---|---|---:|
| OK | Normal operation | 0 |
| WARNING | Resource requires attention | 1 |
| CRITICAL | Serious resource issue | 2 |

## Recovery Detection

The tool stores the previous state of CPU, memory, and disk usage.

It generates alerts when a resource changes state and reports when a previously unhealthy resource returns to `OK`.

## Project Structure

```text
linux-server-monitor/
├── monitor.sh
├── README.md
├── .gitignore
├── logs/
└── state/


## Docker

Build the image:

```bash
docker build -t linux-server-monitor:1.0 .


Run the container:

docker run --rm linux-server-monitor:1.0

Run with persistent logs and state:

docker run --rm \
  -v "$(pwd)/logs:/app/logs" \
  -v "$(pwd)/state:/app/state" \
  linux-server-monitor:1.0

Docker Compose

Start the application:

docker compose up --build


## CI/CD

This project uses GitHub Actions for continuous integration.

The pipeline automatically:

1. Checks out the repository
2. Validates Bash syntax
3. Runs automated tests
4. Builds the Docker image
5. Runs the Docker container
6. Verifies expected application output

Workflow file:

```text
.github/workflows/ci.yml
