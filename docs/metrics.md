# Prometheus metrics

`GET /metrics` serves Prometheus text format (`text/plain; version=0.0.4`). It's off until you set a token.

## Enabling

Set `METRICS_TOKEN` in `.env` on the web **and** Sidekiq containers (both need it: Sidekiq records job timings, web serves the scrape), then restart them:

```bash
METRICS_TOKEN=$(openssl rand -hex 32)
```

- Unset or empty: `/metrics` returns `404` and nothing is recorded.
- Set: requests need `Authorization: Bearer <METRICS_TOKEN>`; anything else gets `401`. Library API keys and signed-in sessions don't work here.

```bash
curl -H "Authorization: Bearer $METRICS_TOKEN" https://library.example.com/metrics
```

Prometheus scrape config:

```yaml
scrape_configs:
  - job_name: library
    metrics_path: /metrics
    scheme: https
    authorization:
      credentials_file: /etc/prometheus/library_token   # or `credentials: <token>`
    static_configs:
      - targets: [library.example.com]
```

Only web processes serve the endpoint, but job and request measurements are accumulated in Redis by every process, so a scrape of any web instance covers the whole deployment. Point Prometheus at one address (the load balancer is fine) rather than scraping each web container, or counters will be duplicated across series.

## Metrics

All names start with `library_`. Times are seconds, sizes are bytes, timestamps are unix seconds.

### Jobs (Sidekiq)

Recorded by a Sidekiq server middleware, per job class and queue. Counters live in Redis and persist across restarts.

| Metric | Type | Labels | Notes |
| --- | --- | --- | --- |
| `library_job_executions_total` | counter | `job`, `queue`, `status` (`success`/`failure`) | Failures count every attempt, retries included |
| `library_job_duration_seconds` | histogram | `job`, `queue` | Run time |
| `library_job_last_run_timestamp_seconds` | gauge | `job`, `status` | Last finish per outcome |
| `library_sidekiq_processed_total` / `library_sidekiq_failed_total` | counter | | Sidekiq's own totals |
| `library_sidekiq_enqueued`, `_scheduled`, `_retries`, `_dead`, `_busy` | gauge | | Set sizes, running jobs |
| `library_sidekiq_queue_size`, `library_sidekiq_queue_latency_seconds` | gauge | `queue` | Backlog and oldest-job age |
| `library_sidekiq_retries_by_job`, `_dead_by_job`, `_scheduled_by_job` | gauge | `job` | First 1000 entries scanned |
| `library_sidekiq_running_by_job` | gauge | `job` | Executing right now |
| `library_sidekiq_cron_job_info` | gauge | `name`, `job`, `cron`, `status` | Recurring jobs |
| `library_sidekiq_cron_last_enqueue_timestamp_seconds` | gauge | `name` | |

### Servers (Sidekiq processes)

| Metric | Type | Labels |
| --- | --- | --- |
| `library_sidekiq_processes`, `library_sidekiq_servers` | gauge | |
| `library_sidekiq_process_info` | gauge | `hostname`, `pid`, `version`, `queues`, `tag` |
| `library_sidekiq_process_concurrency`, `_busy`, `_quiet`, `_rss_kilobytes`, `_started_timestamp_seconds` | gauge | `hostname`, `pid` |

### HTTP requests

Recorded per controller action (the metrics endpoint is excluded).

| Metric | Type | Labels |
| --- | --- | --- |
| `library_http_requests_total` | counter | `controller`, `action`, `status` |
| `library_http_request_duration_seconds` | histogram | `controller`, `action` |
| `library_http_request_db_seconds_total`, `library_http_request_view_seconds_total` | counter | `controller`, `action` |

### Library data

| Metric | Labels |
| --- | --- |
| `library_users`, `library_users_with_slack` | |
| `library_users_by_role` | `role` (`admin`, `editor`, `member`) |
| `library_users_by_auth_provider` | `provider` (`local` for passwords) |
| `library_books`, `library_book_copies`, `library_books_without_location` | |
| `library_books_by_metadata_source`, `library_books_by_location` | `source`, `location` |
| `library_book_views`, `library_book_nfc_views`, `library_book_borrows` | |
| `library_books_last_updated_timestamp_seconds` | |
| `library_authors`, `_subjects`, `_isbns`, `_publishers`, `_locations` | |
| `library_loans` | `state` (`active`, `overdue`, `due_today`, `returned`) |
| `library_loan_max_days_overdue`, `library_loans_by_borrower_active_max` | |
| `library_api_keys`, `library_api_key_last_used_timestamp_seconds` | `name` |
| `library_stored_files`, `library_stored_bytes` | |

### Runtime and scrape health

| Metric | Labels |
| --- | --- |
| `library_info` | `version`, `ruby_version`, `rails_version`, `environment` |
| `library_process_start_time_seconds` | |
| `library_db_pool_connections` | `state` (`size`, `connections`, `busy`, `idle`, `waiting`) — this web process |
| `library_db_size_bytes` | |
| `library_scrape_collector_success`, `library_scrape_collector_duration_seconds` | `collector` (`application`, `database`, `sidekiq`, `jobs`, `requests`) |

Each collector runs independently. If Redis or the database is down, the others still report and `library_scrape_collector_success{collector="…"}` is `0` for the failed one.

## Example alerts

```yaml
- alert: LibraryJobFailures
  expr: increase(library_job_executions_total{status="failure"}[1h]) > 0
- alert: LibraryDeadJobs
  expr: library_sidekiq_dead > 0
- alert: LibraryQueueBacklog
  expr: library_sidekiq_queue_latency_seconds > 300
- alert: LibrarySidekiqDown
  expr: library_sidekiq_processes == 0
- alert: LibraryScrapeDegraded
  expr: library_scrape_collector_success == 0
- alert: LibraryOverdueLoans
  expr: library_loan_max_days_overdue > 14
```

## Notes

- Labels like job class, controller/action, location and API key name are bounded by the app's own code and admin-managed data, so cardinality stays small.
- Request and job counters are cumulative since they were first recorded; use `rate()`/`increase()`. They reset only if Redis is flushed.
- Book view/borrow totals are gauges (sums of per-book counters), not counters: they drop if books are deleted.
