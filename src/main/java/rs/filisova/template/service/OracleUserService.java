package rs.filisova.template.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import rs.filisova.template.dto.OracleUserDTO;
import rs.filisova.template.entity.OracleUserEntity;
import rs.filisova.template.enums.OracleUserGrant;
import rs.filisova.template.enums.OracleUserRole;
import rs.filisova.template.repository.OracleUserRepository;

import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class OracleUserService {

    private final OracleUserRepository oracleUserRepository;

    private OracleUserDTO mapToDTO(OracleUserEntity entity) {
        OracleUserDTO dto = new OracleUserDTO();
        dto.setId(entity.getId());
        dto.setName(entity.getName());
        dto.setBirthDateOra(entity.getBirthDateOra());
        dto.setSex(entity.getSex());
        
        if (entity.getRole() != null) {
            dto.setRole(Arrays.stream(OracleUserRole.values())
                    .filter(r -> r.getId().equals(entity.getRole().getId()))
                    .findFirst()
                    .orElse(null));
        }
        
        if (entity.getGrant() != null) {
            dto.setGrant(Arrays.stream(OracleUserGrant.values())
                    .filter(g -> g.getId().equals(entity.getGrant().getId()))
                    .findFirst()
                    .orElse(null));
        }
        
        return dto;
    }

    public List<OracleUserDTO> getAllUsers() {
        log.info("Getting all Oracle users");
        return oracleUserRepository.findAll().stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public OracleUserDTO getUserById(Long id) {
        log.info("Getting Oracle user by ID: {}", id);
        OracleUserEntity entity = oracleUserRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Oracle user not found with id: " + id));
        return mapToDTO(entity);
    }

    @Transactional("oracleTransactionManager")
    public void createUser(OracleUserDTO dto) {
        log.info("Creating Oracle user via SQL: {}", dto);
        Long roleId = dto.getRole() != null ? dto.getRole().getId() : null;
        Long grantId = dto.getGrant() != null ? dto.getGrant().getId() : null;
        oracleUserRepository.insertUser(dto.getName(), dto.getBirthDateOra(), dto.getSex(), roleId, grantId);
    }

    @Transactional("oracleTransactionManager")
    public void updateUser(Long id, OracleUserDTO dto) {
        log.info("Updating Oracle user via SQL: id={}, dto={}", id, dto);
        Long roleId = dto.getRole() != null ? dto.getRole().getId() : null;
        Long grantId = dto.getGrant() != null ? dto.getGrant().getId() : null;
        oracleUserRepository.updateUser(id, dto.getName(), dto.getBirthDateOra(), dto.getSex(), roleId, grantId);
    }

    @Transactional("oracleTransactionManager")
    public void deleteUser(Long id) {
        log.info("Deleting Oracle user: {}", id);
        oracleUserRepository.deleteById(id);
    }
}
