package rs.filisova.template.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import rs.filisova.template.enums.OracleUserGrant;
import rs.filisova.template.enums.OracleUserRole;

import java.time.LocalDate;

@Data
@Schema(description = "DTO для создания и обновления пользователя Oracle")
public class OracleUserDTO {

    @Schema(description = "Идентификатор пользователя", example = "1")
    private Long id;

    @Schema(description = "Имя пользователя", example = "Ivan Petrov")
    private String name;

    @Schema(description = "Дата рождения", example = "1990-05-15")
    private LocalDate birthDateOra;

    @Schema(description = "Пол (M/F)", example = "M")
    private String sex;

    @Schema(description = "Роль пользователя")
    private OracleUserRole role;

    @Schema(description = "Грант пользователя")
    private OracleUserGrant grant;
}
