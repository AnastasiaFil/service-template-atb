package rs.filisova.template.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalDate;

@Data
public class PostgresUserDTO {

    @Schema(description = "Идентификатор пользователя")
    private Long id;

    @NotBlank
    @Size(min = 3, max = 100)
    @Schema(description = "Имя пользователя")
    private String name;

    @Past(message = "Birth date must be in the past")
    @Schema(description = "Дата рождения")
    private LocalDate birthDate;

    @Size(max = 50)
    @Schema(description = "Пол")
    private String gender;

    @NotBlank
    @Size(max = 100)
    @Schema(description = "Роль пользователя")
    private String role;

    @Size(max = 255)
    @Schema(description = "Грант")
    private String grantField;
}
