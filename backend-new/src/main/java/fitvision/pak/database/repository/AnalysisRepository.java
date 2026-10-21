package fitvision.pak.database.repository;
import fitvision.pak.model.AnalysisTask;
import java.util.Optional;
import java.util.UUID;

public interface AnalysisRepository {
    AnalysisTask save(AnalysisTask task);
    Optional<AnalysisTask> findById(UUID id);
}
