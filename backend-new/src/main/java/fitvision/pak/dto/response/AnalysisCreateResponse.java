package fitvision.pak.dto.response;

import fitvision.pak.model.AnalysisStatus;
import java.time.Instant;
import java.util.UUID;

public record AnalysisCreateResponse(
    UUID analysisId,
    AnalysisStatus status,
    String uploadUrl,
    Instant uploadUrlExpiresAt
) {}
