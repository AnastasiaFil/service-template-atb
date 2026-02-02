package rs.filisova.template.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "DTO для роли пользователя Oracle")
public class OracleUserRoleDTO {

    @Schema(description = "Идентификатор роли", example = "1")
    private Long id;

    @Schema(description = "Название роли", example = "USER")
    private String name;

    @Schema(description = "Описание роли", example = "Basic user role with read-only access")
    private String description;
}
