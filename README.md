# Docker container for PostgreSQL Backup

A minimal Alpine Linux container that dumps a PostgreSQL database on a cron schedule and uploads the backup to a remote storage provider using rclone.

## How it works

On startup, the container snapshots its environment to a file (so cron jobs can access it), installs a crontab from the `BACKUP_SCHEDULE` variable (defaulting to midnight daily), and runs `crond` in the foreground. Each scheduled run:

1. Dumps the database using `pg_dump --format=custom`
2. Uploads the dump file to the configured rclone remote

A lockfile (`flock`) prevents overlapping runs, and failed backups can optionally send notifications to a webhook (e.g. Discord).

## Configuration

### Environment variables

| Variable | Default | Description |
|---|---|---|
| `BACKUP_SCHEDULE` | `0 0 * * *` | Cron schedule for the backup job |
| `NOTIFY_FAILURE_WEBHOOK_URL` | | *(Optional)* Webhook URL for failure notifications |
| `NOTIFY_FAILURE_USERNAME` | | *(Optional)* Username for failure notifications |
| `POSTGRES_HOST` | | PostgreSQL server hostname |
| `POSTGRES_PORT` | | PostgreSQL server port |
| `POSTGRES_USER` | | PostgreSQL username |
| `POSTGRES_PASSWORD` | | PostgreSQL password |
| `POSTGRES_DB` | | Database name to back up |
| `RCLONE_CONFIG` | `/root/.config/rclone/rclone.conf` | *(Optional)* Path to the rclone configuration file |
| `RCLONE_REMOTE` | | Rclone remote and path for uploads (e.g. `b2:my-bucket`) |

### Rclone configuration

To configure a remote interactively:

```sh
docker exec -it <container> rclone config
```

Mount a volume at the config file's parent directory to persist the configuration across container restarts. Set `RCLONE_CONFIG` to change the config file location.

## Running a manual backup

```sh
docker exec <container> /usr/local/bin/backup
```

## License

This project is licensed under the Apache-2.0 License - see the LICENSE file for details.
