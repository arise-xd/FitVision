package fitvision.pak.service;

import com.fasterxml.jackson.databind.ObjectMapper;
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

    // Запускаем каждые 5 секунд
    @Scheduled(fixedDelay = 5000)
    @Transactional
    public void publishMessages() {
        List<OutboxMessage> pendingMessages = outboxRepository.findByStatus("PENDING");

        for (OutboxMessage message : pendingMessages) {
            try {
                AnalysisMessage analysisMessage = objectMapper.readValue(message.getPayload(), AnalysisMessage.class);

                // Отправляем в RabbitMQ
                rabbitTemplate.convertAndSend(RabbitConfig.ANALYSIS_QUEUE, analysisMessage);

                // Помечаем как отправленное
                message.setStatus("SENT");
                outboxRepository.save(message);

                System.out.println("Message sent to RabbitMQ from Outbox: " + analysisMessage.id());
            } catch (Exception e) {
                System.err.println("Failed to send message: " + message.getId() + ". Will retry.");
                // Оставляем статус PENDING, чтобы попробовать снова в следующую итерацию
            }
        }
    }
}
