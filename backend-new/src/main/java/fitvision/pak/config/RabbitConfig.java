package fitvision.pak.config;

import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.QueueBuilder;
import org.springframework.amqp.support.converter.JacksonJsonMessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitConfig {

    public static final String ANALYSIS_QUEUE = "analysis_queue";
    public static final String ANALYSIS_DLQ = "analysis_dlq";

//    @Bean
//    public Queue analysisQueue() {
//        return new Queue(ANALYSIS_QUEUE, true);
//    }

    @Bean
    public Queue analysisQueue() {
        return QueueBuilder.durable(ANALYSIS_QUEUE)
            .withArgument("x-dead-letter-exchange", "")
            .withArgument("x-dead-letter-routing-key", ANALYSIS_DLQ)
            .build();
    }

    @Bean
    public Queue deadLetterQueue() {
        return QueueBuilder.durable(ANALYSIS_DLQ).build();
    }

    @Bean
    public JacksonJsonMessageConverter messageConverter() {
        return new JacksonJsonMessageConverter();
    }
}
