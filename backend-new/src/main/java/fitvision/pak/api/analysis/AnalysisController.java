package fitvision.pak.api.analysis;

import fitvision.pak.database.services.AnalysisService;
import fitvision.pak.dto.requests.AnalysisCreateRequest;
import fitvision.pak.dto.response.AnalysisCreateResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/analyses")
public class AnalysisController {

    private final AnalysisService analysisService;

    public AnalysisController(AnalysisService analysisService) {
        this.analysisService = analysisService;
    }

    @PostMapping
    public ResponseEntity<AnalysisCreateResponse> createAnalysis(
        @Valid @RequestBody AnalysisCreateRequest request) {

        AnalysisCreateResponse response = analysisService.createAnalysis(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
}
