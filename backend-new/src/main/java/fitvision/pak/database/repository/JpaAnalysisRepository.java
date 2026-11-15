package fitvision.pak.database.repository;

import fitvision.pak.database.entity.AnalysisTaskEntity;
import fitvision.pak.model.AnalysisStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface JpaAnalysisRepository extends JpaRepository<AnalysisTaskEntity, UUID> {
    @Modifying
    @Query("UPDATE AnalysisTaskEntity t SET t.status = :newStatus WHERE t.id = :id AND t.status = :currentStatus")
    int updateStatusIfMatch(@Param("id") UUID id,
                            @Param("newStatus") AnalysisStatus newStatus,
                            @Param("currentStatus") AnalysisStatus currentStatus);
}
