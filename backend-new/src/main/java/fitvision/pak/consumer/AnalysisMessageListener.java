package fitvision.pak.consumer;

import fitvision.pak.client.MlClient;
import fitvision.pak.config.RabbitConfig;
import fitvision.pak.database.entity.AnalysisTaskEntity;
import fitvision.pak.database.repository.JpaAnalysisRepository;
import fitvision.pak.dto.AnalysisMessage;
import fitvision.pak.dto.requests.MlAnalysisRequest;
import fitvision.pak.dto.response.MlAcceptedResponse;
import fitvision.pak.service.S3Service;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

@Component
public class AnalysisMessageListener {

    private final JpaAnalysisRepository repository;
    private final S3Service s3Service;
    private final MlClient mlClient;

    public AnalysisMessageListener(JpaAnalysisRepository repository,
                                   S3Service s3Service,
                                   MlClient mlClient) {
        this.repository = repository;
        this.s3Service = s3Service;
        this.mlClient = mlClient;
    }

    @RabbitListener(queues = RabbitConfig.ANALYSIS_QUEUE)
    public void handleAnalysisMessage(AnalysisMessage message) {
        // Idempotency check
        AnalysisTaskEntity task = repository.findById(message.analysisId()).orElse(null);
        if (task == null || task.getStatus() == fitvision.pak.model.AnalysisStatus.DONE) {
            System.out.println("Task already processed or not found: " + message.analysisId());
            return;
        }

        String videoUrl = s3Service.generateDownloadUrl(message.videoKey());

        MlAnalysisRequest mlRequest = new MlAnalysisRequest(
            message.analysisId(),
            message.exercise().name(),
            message.view().name(),
            videoUrl
        );

        try {
            MlAcceptedResponse response = mlClient.sendForAnalysis(mlRequest);
            System.out.println("ML accepted task: " + response.analysisId());
        } catch (Exception e) {
            System.err.println("ML service is unavailable. Will retry...");
            throw e;
        }
    }
}
