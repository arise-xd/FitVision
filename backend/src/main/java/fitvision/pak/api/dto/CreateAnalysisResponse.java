package fitvision.pak.api.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.UUID;

public record CreateAnalysisResponse(
    @JsonProperty("analysis_id")
    UUID analysisId,

    String status
) {
}
