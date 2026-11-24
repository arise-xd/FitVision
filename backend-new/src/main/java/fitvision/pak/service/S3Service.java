package fitvision.pak.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;

import java.time.Duration;
import java.time.Instant;

@Service
public class S3Service {
    private final S3Presigner presigner;

    @Value("${aws.bucket}")
    private String bucket;

    public S3Service(S3Presigner presigner) {
        this.presigner = presigner;
    }

    public String generateDownloadUrl(String videoKey) {
        GetObjectRequest getObjectRequest = GetObjectRequest.builder()
            .bucket(bucket)
            .key(videoKey)
            .build();

        GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
            .signatureDuration(Duration.ofMinutes(15))
            .getObjectRequest(getObjectRequest)
            .build();

        return presigner.presignGetObject(presignRequest).url().toString();
    }

    public PresignedUrl generateUploadUrl(String videoKey) {
        PutObjectRequest objectRequest = PutObjectRequest.builder()
            .bucket(bucket)
            .key(videoKey)
            .build();

        // link will be existing for 15 minutes
        PutObjectPresignRequest presignRequest = PutObjectPresignRequest.builder()
            .signatureDuration(Duration.ofMinutes(15))
            .putObjectRequest(objectRequest)
            .build();

        String url = presigner.presignPutObject(presignRequest).url().toString();
        return new PresignedUrl(url, Instant.now().plus(Duration.ofMinutes(15)));
    }

    public record PresignedUrl(String url, Instant expiresAt) {}
}
