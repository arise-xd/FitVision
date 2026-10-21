package fitvision.pak.database.repository.impl;
import fitvision.pak.database.repository.AnalysisRepository;
import fitvision.pak.model.AnalysisTask;
import org.springframework.stereotype.Repository;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Repository
public class InMemoryAnalysisRepository implements AnalysisRepository {
    private final Map<UUID, AnalysisTask> store = new ConcurrentHashMap<>();

    @Override
    public AnalysisTask save(AnalysisTask task) {
        store.put(task.id(), task);
        return task;
    }

    @Override
    public Optional<AnalysisTask> findById(UUID id) {
        return Optional.ofNullable(store.get(id));
    }
}
