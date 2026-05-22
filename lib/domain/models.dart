// Plain domain enums shared across layers.

/// Lifecycle of a downloaded episode file. Stored in drift via its index.
enum DownloadState { notDownloaded, queued, downloading, downloaded, failed }
