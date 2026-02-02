package rs.filisova.template.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "DTO для гранта пользователя Oracle")
public class OracleUserGrantDTO {

    @Schema(description = "Идентификатор гранта", example = "1")
    private Long id;

    @Schema(description = "Название гранта", example = "READ_ACCESS")
    private String name;

    @Schema(description = "Описание гранта", example = "Permission to read data from database tables")
    private String description;
}
