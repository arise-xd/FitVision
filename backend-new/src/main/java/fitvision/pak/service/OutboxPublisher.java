package fitvision.pak.service;

import tools.jackson.databind.ObjectMapper;
import fitvision.pak.config.RabbitConfig;
import fitvision.pak.database.entity.OutboxMessage;
import fitvision.pak.database.repository.OutboxRepository;
import fitvision.pak.dto.AnalysisMessage;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class OutboxPublisher {

    private final OutboxRepository outboxRepository;
    private final RabbitTemplate rabbitTemplate;
    private final ObjectMapper objectMapper;

    public OutboxPublisher(OutboxRepository outboxRepository,
                           RabbitTemplate rabbitTemplate,
                           ObjectMapper objectMapper) {
        this.outboxRepository = outboxRepository;
        this.rabbitTemplate = rabbitTemplate;
        this.objectMapper = objectMapper;
    }

    // turn on every 5 seconds
    @Scheduled(fixedDelay = 5000)
    @Transactional
    public void publishMessages() {
        List<OutboxMessage> pendingMessages = outboxRepository.findByStatus("PENDING");

        for (OutboxMessage message : pendingMessages) {
            try {
                AnalysisMessage analysisMessage = objectMapper.readValue(message.getPayload(), AnalysisMessage.class);

                // send to RabbitMQ
                rabbitTemplate.convertAndSend(RabbitConfig.ANALYSIS_QUEUE, analysisMessage);

                // marked it how sent
                message.setStatus("SENT");
                outboxRepository.save(message);

                System.out.println("Message sent to RabbitMQ from Outbox: " + analysisMessage.analysisId());
            } catch (Exception e) {
                System.err.println("Failed to send message: " + message.getId() + ". Will retry.");
                // stayed status PENDING, that will try again in next integration
            }
        }
    }
}
