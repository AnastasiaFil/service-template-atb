package rs.filisova.template.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import rs.filisova.template.entity.OracleUserEntity;
import rs.filisova.template.entity.OracleUserGrantEntity;
import rs.filisova.template.entity.OracleUserRoleEntity;
import rs.filisova.template.service.OracleUserGrantService;
import rs.filisova.template.service.OracleUserRoleService;
import rs.filisova.template.service.OracleUserService;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/oracle/")
@RequiredArgsConstructor
@Tag(name = "Oracle Users", description = "API для управления пользователями, грантами и ролями в Oracle")
public class OracleUserController {

    private final OracleUserService oracleUserService;
    private final OracleUserGrantService oracleUserGrantService;
    private final OracleUserRoleService oracleUserRoleService;

    // ===== Oracle Users =====

    @GetMapping("users")
    @Operation(summary = "Получение всех пользователей из БД Oracle")
    public List<OracleUserEntity> getAllUsers() {
        log.info("Get all Oracle users");
        return oracleUserService.getAllUsers();
    }

    @GetMapping("users/{id}")
    @Operation(summary = "Получение пользователя по ID")
    public OracleUserEntity getUserById(@PathVariable Long id) {
        log.info("Get Oracle user by ID: {}", id);
        return oracleUserService.getUserById(id);
    }

    @PostMapping("users")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Создание нового пользователя")
    public void createUser(@RequestBody OracleUserEntity user) {
        log.info("Create Oracle user: {}", user);
        oracleUserService.createUser(user.getName(), user.getBirthDateOra(), user.getSex());
    }

    @PutMapping("users/{id}")
    @Operation(summary = "Обновление данных пользователя")
    public void updateUser(@PathVariable Long id, @RequestBody OracleUserEntity user) {
        log.info("Update Oracle user ID {}: {}", id, user);
        oracleUserService.updateUser(id, user.getName(), user.getBirthDateOra(), user.getSex());
    }

    @DeleteMapping("users/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Удаление пользователя")
    public void deleteUser(@PathVariable Long id) {
        log.info("Delete Oracle user: {}", id);
        oracleUserService.deleteUser(id);
    }

    // ===== Oracle User Grants =====

    @GetMapping("grants")
    @Operation(summary = "Получение всех грантов пользователей")
    public List<OracleUserGrantEntity> getAllGrants() {
        log.info("Get all Oracle user grants");
        return oracleUserGrantService.getAllGrants();
    }

    @GetMapping("grants/{id}")
    @Operation(summary = "Получение гранта по ID")
    public OracleUserGrantEntity getGrantById(@PathVariable Long id) {
        log.info("Get Oracle user grant by ID: {}", id);
        return oracleUserGrantService.getGrantById(id);
    }

    @PostMapping("grants")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Создание нового гранта")
    public void createGrant(@RequestBody OracleUserGrantEntity grant) {
        log.info("Create Oracle user grant: {}", grant);
        oracleUserGrantService.createGrant(grant.getName(), grant.getDescribe());
    }

    @PutMapping("grants/{id}")
    @Operation(summary = "Обновление данных гранта")
    public void updateGrant(@PathVariable Long id, @RequestBody OracleUserGrantEntity grant) {
        log.info("Update Oracle user grant ID {}: {}", id, grant);
        oracleUserGrantService.updateGrant(id, grant.getName(), grant.getDescribe());
    }

    @DeleteMapping("grants/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Удаление гранта")
    public void deleteGrant(@PathVariable Long id) {
        log.info("Delete Oracle user grant: {}", id);
        oracleUserGrantService.deleteGrant(id);
    }

    // ===== Oracle User Roles =====

    @GetMapping("roles")
    @Operation(summary = "Получение всех ролей пользователей")
    public List<OracleUserRoleEntity> getAllRoles() {
        log.info("Get all Oracle user roles");
        return oracleUserRoleService.getAllRoles();
    }

    @GetMapping("roles/{id}")
    @Operation(summary = "Получение роли по ID")
    public OracleUserRoleEntity getRoleById(@PathVariable Long id) {
        log.info("Get Oracle user role by ID: {}", id);
        return oracleUserRoleService.getRoleById(id);
    }

    @PostMapping("roles")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Создание новой роли")
    public void createRole(@RequestBody OracleUserRoleEntity role) {
        log.info("Create Oracle user role: {}", role);
        oracleUserRoleService.createRole(role.getName(), role.getDescribe());
    }

    @PutMapping("roles/{id}")
    @Operation(summary = "Обновление данных роли")
    public void updateRole(@PathVariable Long id, @RequestBody OracleUserRoleEntity role) {
        log.info("Update Oracle user role ID {}: {}", id, role);
        oracleUserRoleService.updateRole(id, role.getName(), role.getDescribe());
    }

    @DeleteMapping("roles/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Удаление роли")
    public void deleteRole(@PathVariable Long id) {
        log.info("Delete Oracle user role: {}", id);
        oracleUserRoleService.deleteRole(id);
    }
}
