package fitvision.pak.database.entity;

import fitvision.pak.model.AnalysisStatus;
import fitvision.pak.model.Exercise;
import fitvision.pak.model.ViewType;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "analysis_tasks")
public class AnalysisTaskEntity {

    @Getter
    @Id
    @Column(nullable = false, updatable = false)
    private UUID id;

    @Getter
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 50)
    private Exercise exercise;

    @Getter
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ViewType view;

    @Getter
    @Column(name = "video_key", nullable = false, length = 255)
    private String videoKey;

    @Getter
    @Setter
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private AnalysisStatus status;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "result_json", columnDefinition = "jsonb")
    private String resultJson;

    @Column(name = "error_message", columnDefinition = "TEXT")
    private String errorMessage;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    // Empty constructor for Hibernate
    public AnalysisTaskEntity() {}

    // Constructor for creating new task
    public AnalysisTaskEntity(UUID id, Exercise exercise, ViewType view, String videoKey, AnalysisStatus status) {
        this.id = id;
        this.exercise = exercise;
        this.view = view;
        this.videoKey = videoKey;
        this.status = status;
    }
}
