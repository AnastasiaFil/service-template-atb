package rs.filisova.template.dto.enums;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
@JsonFormat(shape = JsonFormat.Shape.OBJECT)
public enum OracleUserRole {
    USER(1L, "USER", "Basic user role with read-only access"),
    DEVELOPER(2L, "DEVELOPER", "Developer role with read and write access"),
    ANALYST(3L, "ANALYST", "Analyst role with read and execute access"),
    MANAGER(4L, "MANAGER", "Manager role with extended permissions"),
    ADMINISTRATOR(5L, "ADMINISTRATOR", "Administrator role with full access");

    @JsonProperty("id")
    private final Long id;
    
    @JsonProperty("name")
    private final String name;
    
    @JsonProperty("description")
    private final String description;
}
