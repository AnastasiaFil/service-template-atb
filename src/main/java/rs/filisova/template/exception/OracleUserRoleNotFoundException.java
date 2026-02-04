package rs.filisova.template.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.NOT_FOUND)
public class OracleUserRoleNotFoundException extends RuntimeException {
    public OracleUserRoleNotFoundException(Long id) {
        super("Oracle user role not found with id: " + id);
    }
}
