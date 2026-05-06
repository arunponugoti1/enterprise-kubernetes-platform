output "bucket_name" {
  description = "Name of the tamper-evident audit log GCS bucket."
  value       = google_storage_bucket.audit_logs.name
}

output "sink_writer_identity" {
  description = "Service account identity of the log sink writer."
  value       = google_logging_project_sink.audit_logs.writer_identity
}
