package fitvision.pak.database.services;

import fitvision.pak.dto.response.AnalysisDetailsResponse;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.ObjectMapper;
import fitvision.pak.database.entity.AnalysisTaskEntity;
import fitvision.pak.database.entity.OutboxMessage;
import fitvision.pak.database.repository.JpaAnalysisRepository;
import fitvision.pak.database.repository.OutboxRepository;
import fitvision.pak.dto.AnalysisMessage;
import fitvision.pak.dto.requests.AnalysisCreateRequest;
import fitvision.pak.dto.response.AnalysisCreateResponse;
import fitvision.pak.exception.InvalidTaskStateException;
import fitvision.pak.exception.TaskNotFoundException;
import fitvision.pak.model.AnalysisStatus;
import fitvision.pak.service.S3Service;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
public class AnalysisService {

    private final JpaAnalysisRepository repository;
    private final OutboxRepository outboxRepository;
    private final S3Service s3Service;
    private final ObjectMapper objectMapper; // for translating message in JSON

    public AnalysisService(JpaAnalysisRepository repository,
                           OutboxRepository outboxRepository,
                           S3Service s3Service,
                           ObjectMapper objectMapper) {
        this.repository = repository;
        this.outboxRepository = outboxRepository;
        this.s3Service = s3Service;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public AnalysisCreateResponse createAnalysis(AnalysisCreateRequest request) {
        AnalysisTaskEntity entity = new AnalysisTaskEntity(
            UUID.randomUUID(),
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
        // checked existing (404)
        AnalysisTaskEntity task = repository.findById(id)
            .orElseThrow(() -> new TaskNotFoundException("Task not found with id: " + id));

        // upload status (409 if not QUEUED)
        int updatedRows = repository.updateStatusIfMatch(id, AnalysisStatus.PROCESSING, AnalysisStatus.QUEUED);

        if (updatedRows == 0) {
            throw new InvalidTaskStateException("Task is not in QUEUED state or already processed");
        }

        AnalysisMessage message = new AnalysisMessage(
            task.getId(),
            task.getVideoKey(),
            task.getExercise(),
            task.getView()
        );

        // save in Transactional Outbox
        try {
            String payload = objectMapper.writeValueAsString(message);
            OutboxMessage outboxMessage = new OutboxMessage(
                UUID.randomUUID(),
                payload,
                "PENDING",
                LocalDateTime.now()
            );
            outboxRepository.save(outboxMessage);
        } catch (JacksonException  e) {
            throw new RuntimeException("Failed to serialize message", e);
        }

        System.out.println("Outbox message saved for task: " + task.getId());
    }

    @Transactional
    public void saveResult(UUID id, String resultJson) {
        AnalysisTaskEntity task = repository.findById(id)
            .orElseThrow(() -> new TaskNotFoundException("Task not found with id: " + id));

        if (task.getStatus() != AnalysisStatus.PROCESSING) {
            throw new InvalidTaskStateException("Task is not in PROCESSING state");
        }

        task.setResultJson(resultJson);
        task.setStatus(AnalysisStatus.DONE);
        repository.save(task);
    }

    @Transactional(readOnly = true)
    public AnalysisDetailsResponse getAnalysisDetails(UUID id) {
        AnalysisTaskEntity task = repository.findById(id)
            .orElseThrow(() -> new TaskNotFoundException("Task not found with id: " + id));

        return new AnalysisDetailsResponse(
            task.getId(),
            task.getStatus(),
            task.getResultJson(),
            task.getErrorMessage()
        );
    }

    @Transactional
    public void markAsFailed(UUID id, String errorMessage) {
        AnalysisTaskEntity task = repository.findById(id)
            .orElseThrow(() -> new TaskNotFoundException("Task not found"));
        task.setStatus(AnalysisStatus.FAILED);
        task.setErrorMessage(errorMessage);
        repository.save(task);
    }
}
