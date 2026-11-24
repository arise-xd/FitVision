package fitvision.pak.dto.requests;

import java.util.UUID;

public record MlAnalysisRequest(
    UUID analysisId,
    String exercise,
    String view,
    String videoUrl
) {}
