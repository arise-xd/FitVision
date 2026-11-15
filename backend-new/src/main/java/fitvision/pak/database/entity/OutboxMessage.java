package fitvision.pak.database.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "outbox_messages")
public class OutboxMessage {
    @Id
    @Getter
    @Setter
    private UUID id;
    @Getter
    @Setter
    private String payload; // JSON строка
    @Getter
    @Setter
    private String status; // PENDING, SENT
    @Getter
    @Setter
    private LocalDateTime createdAt;

    public OutboxMessage() {}

    public OutboxMessage(UUID id, String payload, String status, LocalDateTime createdAt) {
        this.id = id;
        this.payload = payload;
        this.status = status;
        this.createdAt = createdAt;
    }
}
