package rs.filisova.template.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import rs.filisova.template.entity.OracleUserEntity;
import rs.filisova.template.repository.OracleUserRepository;

import java.time.LocalDate;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class OracleUserService {

    private final OracleUserRepository oracleUserRepository;

    public List<OracleUserEntity> getAllUsers() {
        log.info("Getting all Oracle users");
        return oracleUserRepository.findAll();
    }

    public OracleUserEntity getUserById(Long id) {
        log.info("Getting Oracle user by ID: {}", id);
        return oracleUserRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Oracle user not found with id: " + id));
    }

    @Transactional("oracleTransactionManager")
    public void createUser(String name, LocalDate birthDateOra, String sex) {
        log.info("Creating Oracle user via SQL: name={}, birthDateOra={}, sex={}", name, birthDateOra, sex);
        oracleUserRepository.insertUser(name, birthDateOra, sex);
    }

    @Transactional("oracleTransactionManager")
    public void updateUser(Long id, String name, LocalDate birthDateOra, String sex) {
        log.info("Updating Oracle user via SQL: id={}, name={}, birthDateOra={}, sex={}", id, name, birthDateOra, sex);
        oracleUserRepository.updateUser(id, name, birthDateOra, sex);
    }

    @Transactional("oracleTransactionManager")
    public void deleteUser(Long id) {
        log.info("Deleting Oracle user: {}", id);
        oracleUserRepository.deleteById(id);
    }
}
