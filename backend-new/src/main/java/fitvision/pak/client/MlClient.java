package fitvision.pak.client;

import fitvision.pak.dto.requests.MlAnalysisRequest;
import fitvision.pak.dto.response.MlAcceptedResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

@Component
public class MlClient {

    private final RestClient restClient;

    public MlClient(@Value("${ml.api.url}") String mlApiUrl) {
        this.restClient = RestClient.builder()
            .baseUrl(mlApiUrl)
            .build();
    }

    public MlAcceptedResponse sendForAnalysis(MlAnalysisRequest request) {
        return restClient.post()
            .uri("/api/v1/analyses")
            .body(request)
            .retrieve()
            .body(MlAcceptedResponse.class);
    }
}
