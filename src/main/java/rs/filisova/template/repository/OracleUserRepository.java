package rs.filisova.template.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import rs.filisova.template.entity.OracleUserEntity;

import java.time.LocalDate;

@Repository
public interface OracleUserRepository extends JpaRepository<OracleUserEntity, Long> {

    @Modifying
    @Query(value = "INSERT INTO oracle_users (name, birth_date_ora, sex, role_id, grant_id) VALUES (:name, :birthDateOra, :sex, :roleId, :grantId)", nativeQuery = true)
    void insertUser(@Param("name") String name, @Param("birthDateOra") LocalDate birthDateOra, @Param("sex") String sex, @Param("roleId") Long roleId, @Param("grantId") Long grantId);

    @Modifying
    @Query(value = "UPDATE oracle_users SET name = :name, birth_date_ora = :birthDateOra, sex = :sex, role_id = :roleId, grant_id = :grantId WHERE id = :id", nativeQuery = true)
    void updateUser(@Param("id") Long id, @Param("name") String name, @Param("birthDateOra") LocalDate birthDateOra, @Param("sex") String sex, @Param("roleId") Long roleId, @Param("grantId") Long grantId);
}
