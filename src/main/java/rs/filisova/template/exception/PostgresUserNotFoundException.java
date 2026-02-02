package rs.filisova.template.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.NOT_FOUND)
public class PostgresUserNotFoundException extends RuntimeException {
    public PostgresUserNotFoundException(Long id) {
        super("PostgresUser not found with id: " + id);
    }
}
