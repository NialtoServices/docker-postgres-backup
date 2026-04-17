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
| `BACKUP_FILENAME_TIMESTAMPED` | `false` | *(Optional)* When `true`, appends a UTC ISO-8601 timestamp to the dump filename so every run produces a new object instead of overwriting |
| `BACKUP_MAX_VERSIONS` | `0` | *(Optional)* When timestamped mode is on and this is > 0, keep only the N most recent dumps and prune the rest after each successful upload |
| `NOTIFY_FAILURE_WEBHOOK_URL` | | *(Optional)* Webhook URL for failure notifications |
| `NOTIFY_FAILURE_USERNAME` | | *(Optional)* Username for failure notifications |
| `POSTGRES_HOST` | | PostgreSQL server hostname |
| `POSTGRES_PORT` | | PostgreSQL server port |
| `POSTGRES_USER` | | PostgreSQL username |
| `POSTGRES_PASSWORD` | | PostgreSQL password |
| `POSTGRES_DB` | | Database name to back up |
| `RCLONE_CONFIG` | `/root/.config/rclone/rclone.conf` | *(Optional)* Path to the rclone configuration file |
| `RCLONE_REMOTE` | | Rclone remote and path for uploads (e.g. `b2:my-bucket`) |

### Retention

By default each backup overwrites the previous one at the same object path — relying on object versioning at your rclone target (S3 versioned buckets, Backblaze B2 file versions, etc.) to keep history.

If your target does not have versioning, set `BACKUP_FILENAME_TIMESTAMPED=true` so each run produces `${POSTGRES_DB}-2026-04-17-00-00-00-UTC.dump` instead. Combine with `BACKUP_MAX_VERSIONS=N` to keep only the N most recent and prune older ones after each run. `BACKUP_MAX_VERSIONS` counts runs, not a time window — with a daily schedule and `BACKUP_MAX_VERSIONS=7` you keep a week; with hourly, seven hours.

Bucket-level lifecycle rules (Backblaze B2 lifecycle, S3 object lifecycle) are an alternative to `BACKUP_MAX_VERSIONS` and let the provider do the pruning on its own schedule.

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

## Running a manual prune

Useful for one-off cleanup or after changing `BACKUP_MAX_VERSIONS`:

```sh
docker exec <container> /usr/local/bin/prune
```

`prune` is also triggered automatically as the final step of each scheduled backup when `BACKUP_FILENAME_TIMESTAMPED=true` and `BACKUP_MAX_VERSIONS` is greater than 0.

## License

This project is licensed under the Apache-2.0 License - see the LICENSE file for details.
