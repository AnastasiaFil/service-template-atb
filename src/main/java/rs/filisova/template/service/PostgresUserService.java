package rs.filisova.template.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import rs.filisova.template.dto.PostgresUserDTO;
import rs.filisova.template.entity.PostgresUserEntity;
import rs.filisova.template.exception.PostgresUserNotFoundException;
import rs.filisova.template.repository.PostgresUserRepository;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class PostgresUserService {

    private final PostgresUserRepository postgresUserRepository;

    @Transactional(readOnly = true)
    public List<PostgresUserDTO> getAllPostgresUsers() {
        List<PostgresUserDTO> postgresUsers = postgresUserRepository.findAllByOrderByIdAsc().stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
        log.info("Retrieved {} postgresUsers", postgresUsers.size());
        return postgresUsers;
    }

    @Transactional(readOnly = true)
    public PostgresUserDTO getPostgresUserById(Long id) {
        PostgresUserEntity postgresUser = postgresUserRepository.findById(id)
                .orElseThrow(() -> new PostgresUserNotFoundException(id));
        PostgresUserDTO postgresUserDTO = convertToDTO(postgresUser);
        log.info("Retrieved postgresUser: {}", postgresUserDTO);
        return postgresUserDTO;
    }

    @Transactional
    public PostgresUserDTO createPostgresUser(PostgresUserDTO postgresUserDTO) {
        PostgresUserEntity postgresUser = convertToEntity(postgresUserDTO);
        PostgresUserEntity savedPostgresUser = postgresUserRepository.save(postgresUser);
        PostgresUserDTO result = convertToDTO(savedPostgresUser);
        log.info("Created postgresUser: {}", result);
        return result;
    }

    @Transactional
    public PostgresUserDTO updatePostgresUser(Long id, PostgresUserDTO postgresUserDTO) {
        PostgresUserEntity existingPostgresUser = postgresUserRepository.findById(id)
                .orElseThrow(() -> new PostgresUserNotFoundException(id));

        existingPostgresUser.setName(postgresUserDTO.getName());
        existingPostgresUser.setBirthDate(postgresUserDTO.getBirthDate());
        existingPostgresUser.setGender(postgresUserDTO.getGender());
        existingPostgresUser.setRole(postgresUserDTO.getRole());
        existingPostgresUser.setGrantField(postgresUserDTO.getGrantField());

        PostgresUserEntity updatedPostgresUser = postgresUserRepository.save(existingPostgresUser);
        PostgresUserDTO result = convertToDTO(updatedPostgresUser);
        log.info("Updated postgresUser: {}", result);
        return result;
    }

    @Transactional
    public void deletePostgresUser(Long id) {
        if (!postgresUserRepository.existsById(id)) {
            throw new PostgresUserNotFoundException(id);
        }
        postgresUserRepository.deleteById(id);
        log.info("Deleted postgresUser with id: {}", id);
    }

    private PostgresUserDTO convertToDTO(PostgresUserEntity postgresUser) {
        PostgresUserDTO dto = new PostgresUserDTO();
        dto.setId(postgresUser.getId());
        dto.setName(postgresUser.getName());
        dto.setBirthDate(postgresUser.getBirthDate());
        dto.setGender(postgresUser.getGender());
        dto.setRole(postgresUser.getRole());
        dto.setGrantField(postgresUser.getGrantField());
        return dto;
    }

    private PostgresUserEntity convertToEntity(PostgresUserDTO dto) {
        PostgresUserEntity entity = new PostgresUserEntity();
        entity.setId(dto.getId());
        entity.setName(dto.getName());
        entity.setBirthDate(dto.getBirthDate());
        entity.setGender(dto.getGender());
        entity.setRole(dto.getRole());
        entity.setGrantField(dto.getGrantField());
        return entity;
    }
}
