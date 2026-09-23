bool isStale(DateTime? lastFetchedAt, Duration threshold) =>
    lastFetchedAt == null || DateTime.now().difference(lastFetchedAt) >= threshold;
