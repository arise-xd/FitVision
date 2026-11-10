package fitvision.pak.database.repository;

import fitvision.pak.database.entity.AnalysisTaskEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface JpaAnalysisRepository extends JpaRepository<AnalysisTaskEntity, UUID> {

}
