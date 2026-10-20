package fitvision.pak.api.analysis;

import fitvision.pak.database.services.AnalysisService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AnalysisController {
    private final AnalysisService analysisService;

    public AnalysisController(AnalysisService analysisService) {
        this.analysisService = analysisService;
    }

    @GetMapping
    public String getServiceResponse() {
        return analysisService.getServiceResponse();
    }
}
