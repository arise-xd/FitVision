package fitvision.pak.dto.response;

import java.util.UUID;

public record MlAcceptedResponse(
    UUID analysisId,
    String status
) {}
