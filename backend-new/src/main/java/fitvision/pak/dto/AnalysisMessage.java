package fitvision.pak.dto;

import fitvision.pak.model.Exercise;
import fitvision.pak.model.ViewType;
import java.util.UUID;

public record AnalysisMessage(
    UUID analysisId,
    String videoKey,
    Exercise exercise,
    ViewType view
) {}
