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
    @Query(value = "INSERT INTO oracle_users (name, birth_date_ora, sex) VALUES (:name, :birthDateOra, :sex)", nativeQuery = true)
    void insertUser(@Param("name") String name, @Param("birthDateOra") LocalDate birthDateOra, @Param("sex") String sex);

    @Modifying
    @Query(value = "UPDATE oracle_users SET name = :name, birth_date_ora = :birthDateOra, sex = :sex WHERE id = :id", nativeQuery = true)
    void updateUser(@Param("id") Long id, @Param("name") String name, @Param("birthDateOra") LocalDate birthDateOra, @Param("sex") String sex);
}
