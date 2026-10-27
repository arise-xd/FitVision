package fitvision.pak.model;

import java.time.Instant;
import java.util.UUID;

public record AnalysisTask(
    UUID id,
    Exercise exercise,
    ViewType view,
    String videoKey,
    AnalysisStatus status,
    Instant createdAt
) {
    public static AnalysisTask createNew(Exercise exercise, ViewType view, String videoKey) {
        return new AnalysisTask(
            UUID.randomUUID(), exercise, view, videoKey,
            AnalysisStatus.QUEUED, Instant.now()
        );
    }
}
