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
    @Pattern(
        regexp = "^videos/[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+\\.(mp4|mov|avi)$",
        message = "videoKey must match videos/{userId}/{filename}.{ext}"
    )
    String videoKey
) {}
