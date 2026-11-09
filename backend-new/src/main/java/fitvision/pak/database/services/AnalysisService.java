package fitvision.pak.database.services;

import fitvision.pak.database.entity.AnalysisTaskEntity;
import fitvision.pak.database.repository.JpaAnalysisRepository;
import fitvision.pak.dto.requests.AnalysisCreateRequest;
import fitvision.pak.dto.response.AnalysisCreateResponse;
import fitvision.pak.model.AnalysisStatus;
import fitvision.pak.model.AnalysisTask;
import fitvision.pak.service.S3Service;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AnalysisService {

    private final JpaAnalysisRepository repository;
    private final S3Service s3Service;

    public AnalysisService(JpaAnalysisRepository repository, S3Service s3Service) {
        this.repository = repository;
        this.s3Service = s3Service;
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
}
