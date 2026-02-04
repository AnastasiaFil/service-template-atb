package rs.filisova.template.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.NOT_FOUND)
public class OracleUserGrantNotFoundException extends RuntimeException {
    public OracleUserGrantNotFoundException(Long id) {
        super("Oracle user grant not found with id: " + id);
    }
}
