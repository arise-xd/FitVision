package fitvision.pak.api.controller;

import fitvision.pak.api.dto.CreateAnalysisResponse;
import fitvision.pak.core.analysis.Analysis;
import fitvision.pak.core.analysis.AnalysisService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/analyses")
public class AnalysisController {

    private final AnalysisService analysisService;

    public AnalysisController(AnalysisService analysisService) {
        this.analysisService = analysisService;
    }

    @PostMapping(consumes = "multipart/form-data")
    public ResponseEntity<CreateAnalysisResponse> createAnalysis(
        @RequestParam("video") MultipartFile video,
        @RequestParam("exercise") String exercise,
        @RequestParam("view") String view
    ) {
        Analysis analysis = analysisService.createAnalysis(
            video,
            exercise,
            view
        );

        CreateAnalysisResponse response =
            new CreateAnalysisResponse(
                analysis.getId(),
                "queued"
            );

        return ResponseEntity
            .accepted()
            .body(response);
    }
}
