package rs.filisova.template.dto.enums;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
@JsonFormat(shape = JsonFormat.Shape.OBJECT)
public enum OracleUserGrant {
    READ_ACCESS(1L, "READ_ACCESS", "Permission to read data from database tables"),
    WRITE_ACCESS(2L, "WRITE_ACCESS", "Permission to insert and update data in database tables"),
    DELETE_ACCESS(3L, "DELETE_ACCESS", "Permission to delete data from database tables"),
    EXECUTE_ACCESS(4L, "EXECUTE_ACCESS", "Permission to execute stored procedures and functions"),
    ADMIN_ACCESS(5L, "ADMIN_ACCESS", "Full administrative access to the database");

    @JsonProperty("id")
    private final Long id;
    
    @JsonProperty("name")
    private final String name;
    
    @JsonProperty("description")
    private final String description;
}
