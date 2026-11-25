CREATE TABLE outbox_messages (
     id UUID PRIMARY KEY,
     payload TEXT NOT NULL,
     status VARCHAR(20) NOT NULL,
     created_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_outbox_status ON outbox_messages(status);
