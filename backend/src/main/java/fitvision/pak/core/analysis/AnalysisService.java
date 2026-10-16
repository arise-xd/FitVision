package fitvision.pak.core.analysis;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.*;
import java.time.Instant;
import java.util.UUID;

@Service
public class AnalysisService {

    private static final long MAX_FILE_SIZE = 100L * 1024 * 1024;

    private final AnalysisRepository analysisRepository;
    private final Path videoStorageDirectory;

    public AnalysisService(
        AnalysisRepository analysisRepository,
        @Value("${fitvision.storage.video-dir}") String videoStorageDirectory
    ) {
        this.analysisRepository = analysisRepository;
        this.videoStorageDirectory = Paths.get(videoStorageDirectory);
    }

    public Analysis createAnalysis(
        MultipartFile video,
        String exercise,
        String view
    ) {
        validateParameters(video, exercise, view);

        UUID analysisId = UUID.randomUUID();

        Path videoPath = saveVideo(video, analysisId);

        Instant now = Instant.now();

        Analysis analysis = new Analysis();

        analysis.setId(analysisId);
        analysis.setExercise(exercise);
        analysis.setView(view);
        analysis.setStatus(AnalysisStatus.QUEUED);
        analysis.setVideoPath(videoPath.toAbsolutePath().toString());
        analysis.setCreatedAt(now);
        analysis.setUpdatedAt(now);

        return analysisRepository.save(analysis);
    }

    private void validateParameters(
        MultipartFile video,
        String exercise,
        String view
    ) {
        if (video == null || video.isEmpty()) {
            throw new IllegalArgumentException("Видео не предоставлено");
        }

        if (video.getSize() > MAX_FILE_SIZE) {
            throw new IllegalArgumentException("Размер видео превышает 100 MB");
        }

        if (!"squat".equalsIgnoreCase(exercise)) {
            throw new IllegalArgumentException(
                "Поддерживается только упражнение squat"
            );
        }

        if (!"front".equalsIgnoreCase(view)
            && !"side".equalsIgnoreCase(view)) {
            throw new IllegalArgumentException(
                "View должен быть front или side"
            );
        }
    }

    private Path saveVideo(
        MultipartFile video,
        UUID analysisId
    ) {
        try {
            Files.createDirectories(videoStorageDirectory);

            Path target = videoStorageDirectory.resolve(
                analysisId + ".mp4"
            );

            try (InputStream inputStream = video.getInputStream()) {
                Files.copy(
                    inputStream,
                    target,
                    StandardCopyOption.REPLACE_EXISTING
                );
            }

            return target;

        } catch (IOException e) {
            throw new RuntimeException(
                "Не удалось сохранить видео",
                e
            );
        }
    }
}
