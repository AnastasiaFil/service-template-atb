package rs.filisova.template.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import rs.filisova.template.entity.PostgresUserEntity;

import java.util.List;

@Repository
public interface PostgresUserRepository extends JpaRepository<PostgresUserEntity, Long> {
    List<PostgresUserEntity> findAllByOrderByIdAsc();
}
