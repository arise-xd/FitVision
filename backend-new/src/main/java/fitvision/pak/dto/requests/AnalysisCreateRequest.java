package fitvision.pak.dto.requests;

import fitvision.pak.model.Exercise;
import fitvision.pak.model.ViewType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

public record AnalysisCreateRequest(
    @NotNull(message = "exercise is required")
    Exercise exercise,

    @NotNull(message = "view is required")
    ViewType view,

    @NotBlank(message = "videoKey is required")
    String videoKey
) {}
