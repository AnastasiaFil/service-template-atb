package rs.filisova.template.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import rs.filisova.template.dto.PostgresUserDTO;
import rs.filisova.template.service.PostgresUserService;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/postgres-users")
@RequiredArgsConstructor
@Tag(name = "Postgres Users", description = "API для управления пользователями в PostgreSQL")
public class PostgresUserController {

    private final PostgresUserService postgresUserService;

    @GetMapping
    @Operation(summary = "Получение всех пользователей из БД PostgreSQL")
    public List<PostgresUserDTO> getAllPostgresUsers() {
        log.info("Get all postgresUsers");
        return postgresUserService.getAllPostgresUsers();
    }

    @GetMapping("/{id}")
    @Operation(summary = "Получение пользователя по ID")
    public PostgresUserDTO getPostgresUserById(@PathVariable Long id) {
        log.info("Get postgresUser by ID {}", id);
        return postgresUserService.getPostgresUserById(id);
    }

    @PostMapping
    @Operation(summary = "Создание нового пользователя")
    public PostgresUserDTO createPostgresUser(@Valid @RequestBody PostgresUserDTO postgresUserDTO) {
        log.info("Create postgresUser {}", postgresUserDTO);
        return postgresUserService.createPostgresUser(postgresUserDTO);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Обновление данных пользователя")
    public PostgresUserDTO updatePostgresUser(@PathVariable Long id, @Valid @RequestBody PostgresUserDTO postgresUserDTO) {
        log.info("Update postgresUser {}", postgresUserDTO);
        return postgresUserService.updatePostgresUser(id, postgresUserDTO);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Удаление пользователя")
    public void deletePostgresUser(@PathVariable Long id) {
        log.info("Delete postgresUser {}", id);
        postgresUserService.deletePostgresUser(id);
    }
}
