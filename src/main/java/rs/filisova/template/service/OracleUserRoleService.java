package rs.filisova.template.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import rs.filisova.template.entity.OracleUserRoleEntity;
import rs.filisova.template.exception.OracleUserRoleNotFoundException;
import rs.filisova.template.repository.OracleUserRoleRepository;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class OracleUserRoleService {

    private final OracleUserRoleRepository oracleUserRoleRepository;

    public List<OracleUserRoleEntity> getAllRoles() {
        log.info("Getting all Oracle user roles");
        return oracleUserRoleRepository.findAll();
    }

    public OracleUserRoleEntity getRoleById(Long id) {
        log.info("Getting Oracle user role by ID: {}", id);
        return oracleUserRoleRepository.findById(id)
                .orElseThrow(() -> new OracleUserRoleNotFoundException(id));
    }

    @Transactional("oracleTransactionManager")
    public void createRole(String name, String describe) {
        log.info("Creating Oracle user role via SQL: name={}, describe={}", name, describe);
        oracleUserRoleRepository.insertRole(name, describe);
    }

    @Transactional("oracleTransactionManager")
    public void updateRole(Long id, String name, String describe) {
        log.info("Updating Oracle user role via SQL: id={}, name={}, describe={}", id, name, describe);
        oracleUserRoleRepository.updateRole(id, name, describe);
    }

    @Transactional("oracleTransactionManager")
    public void deleteRole(Long id) {
        log.info("Deleting Oracle user role: {}", id);
        oracleUserRoleRepository.deleteById(id);
    }
}
