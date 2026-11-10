package fitvision.pak.database.services;

import fitvision.pak.config.RabbitConfig;
import fitvision.pak.database.entity.AnalysisTaskEntity;
import fitvision.pak.database.repository.JpaAnalysisRepository;
import fitvision.pak.dto.AnalysisMessage;
import fitvision.pak.dto.requests.AnalysisCreateRequest;
import fitvision.pak.dto.response.AnalysisCreateResponse;
import fitvision.pak.model.AnalysisStatus;
import fitvision.pak.service.S3Service;
import java.util.UUID;

import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AnalysisService {

    private final JpaAnalysisRepository repository;
    private final S3Service s3Service;
    private final RabbitTemplate rabbitTemplate;

    public AnalysisService(JpaAnalysisRepository repository,
                           S3Service s3Service,
                           RabbitTemplate rabbitTemplate) {
        this.repository = repository;
        this.s3Service = s3Service;
        this.rabbitTemplate = rabbitTemplate;
    }

    @Transactional
    public AnalysisCreateResponse createAnalysis(AnalysisCreateRequest request) {
        AnalysisTaskEntity entity = new AnalysisTaskEntity(
            java.util.UUID.randomUUID(),
            request.exercise(),
            request.view(),
            request.videoKey(),
            AnalysisStatus.QUEUED
        );
        AnalysisTaskEntity savedEntity = repository.save(entity);

        S3Service.PresignedUrl presigned = s3Service.generateUploadUrl(request.videoKey());

        return new AnalysisCreateResponse(
            savedEntity.getId(),
            savedEntity.getStatus(),
            presigned.url(),
            presigned.expiresAt()
        );
    }

    @Transactional
    public void confirmUpload(UUID id) {
        AnalysisTaskEntity task = repository.findById(id)
            .orElseThrow(() -> new RuntimeException("Task not found with id: " + id));

        if (task.getStatus() != AnalysisStatus.QUEUED) {
            throw new IllegalStateException("Task is not in QUEUED state");
        }

        task.setStatus(AnalysisStatus.PROCESSING);
        repository.save(task);

        AnalysisMessage message = new AnalysisMessage(
            task.getId(),
            task.getVideoKey(),
            task.getExercise(),
            task.getView()
        );

        rabbitTemplate.convertAndSend(RabbitConfig.ANALYSIS_QUEUE, message);
        System.out.println("Message sent to RabbitMQ for task: " + task.getId());
    }
}
