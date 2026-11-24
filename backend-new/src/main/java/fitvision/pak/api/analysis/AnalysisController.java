package fitvision.pak.api.analysis;

import fitvision.pak.database.services.AnalysisService;
import fitvision.pak.dto.requests.AnalysisCreateRequest;
import fitvision.pak.dto.response.AnalysisCreateResponse;
import fitvision.pak.dto.response.AnalysisDetailsResponse;
import jakarta.validation.Valid;
import java.util.UUID;
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

    @PostMapping("/{id}/confirm")
    public ResponseEntity<Void> confirmUpload(@PathVariable("id") UUID id) {
        analysisService.confirmUpload(id);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/{id}/result")
    public ResponseEntity<Void> receiveResult(
        @PathVariable("id") UUID id,
        @RequestBody String resultJson) { // принимаем сырой JSON от ML
        analysisService.saveResult(id, resultJson);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/{id}/fail")
    public ResponseEntity<Void> receiveFailure(
        @PathVariable("id") UUID id,
        @RequestBody String errorMessage) {
        analysisService.markAsFailed(id, errorMessage);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/{id}")
    public ResponseEntity<AnalysisDetailsResponse> getAnalysisDetails(@PathVariable("id") UUID id) {
        return ResponseEntity.ok(analysisService.getAnalysisDetails(id));
    }
}
