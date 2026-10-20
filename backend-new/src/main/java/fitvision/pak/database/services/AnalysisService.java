package fitvision.pak.database.services;

import fitvision.pak.database.repository.AnalysisRepository;
import fitvision.pak.dto.requests.AnalysisCreateRequest;
import fitvision.pak.dto.response.AnalysisCreateResponse;
import fitvision.pak.model.AnalysisTask;
import fitvision.pak.service.S3Service;
import org.springframework.stereotype.Service;

@Service
public class AnalysisService {
    private final AnalysisRepository repository;
    private final S3Service s3Service;

    public AnalysisService(AnalysisRepository repository, S3Service s3Service) {
        this.repository = repository;
        this.s3Service = s3Service;
    }

    public AnalysisCreateResponse createAnalysis(AnalysisCreateRequest request) {
        // 1. create task
        AnalysisTask task = AnalysisTask.createNew(request.exercise(), request.view(), request.videoKey());

        // 2. save in memory
        repository.save(task);

        // 3. generate link on MinIO
        S3Service.PresignedUrl presigned = s3Service.generateUploadUrl(request.videoKey());

        // 4. return response
        return new AnalysisCreateResponse(task.id(), task.status(), presigned.url(), presigned.expiresAt());
    }
}
