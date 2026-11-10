CREATE TABLE analysis_tasks (
    id UUID PRIMARY KEY,
    exercise VARCHAR(50) NOT NULL,
    view VARCHAR(20) NOT NULL,
    video_key VARCHAR(255) NOT NULL,
    status VARCHAR(30) NOT NULL,
    result_json JSONB,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);
