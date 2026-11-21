package fitvision.pak;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class BackendNewApplication {

    public static void main(String[] args) {
        SpringApplication.run(BackendNewApplication.class, args);
    }

}
