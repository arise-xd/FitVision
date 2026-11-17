package fitvision.pak.dto.response;

import fitvision.pak.model.AnalysisStatus;
import java.util.UUID;

public record AnalysisDetailsResponse(
    UUID id,
    AnalysisStatus status,
    String resultJson,
    String errorMessage
) {}
