package rs.filisova.template.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import rs.filisova.template.entity.OracleUserGrantEntity;
import rs.filisova.template.repository.OracleUserGrantRepository;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class OracleUserGrantService {

    private final OracleUserGrantRepository oracleUserGrantRepository;

    public List<OracleUserGrantEntity> getAllGrants() {
        log.info("Getting all Oracle user grants");
        return oracleUserGrantRepository.findAll();
    }

    public OracleUserGrantEntity getGrantById(Long id) {
        log.info("Getting Oracle user grant by ID: {}", id);
        return oracleUserGrantRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Oracle user grant not found with id: " + id));
    }

    @Transactional("oracleTransactionManager")
    public void createGrant(String name, String describe) {
        log.info("Creating Oracle user grant via SQL: name={}, describe={}", name, describe);
        oracleUserGrantRepository.insertGrant(name, describe);
    }

    @Transactional("oracleTransactionManager")
    public void updateGrant(Long id, String name, String describe) {
        log.info("Updating Oracle user grant via SQL: id={}, name={}, describe={}", id, name, describe);
        oracleUserGrantRepository.updateGrant(id, name, describe);
    }

    @Transactional("oracleTransactionManager")
    public void deleteGrant(Long id) {
        log.info("Deleting Oracle user grant: {}", id);
        oracleUserGrantRepository.deleteById(id);
    }
}
