package rs.filisova.template.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.NOT_FOUND)
public class OracleUserNotFoundException extends RuntimeException {
    public OracleUserNotFoundException(Long id) {
        super("Oracle user not found with id: " + id);
    }
}
