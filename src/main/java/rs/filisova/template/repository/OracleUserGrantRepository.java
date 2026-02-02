package rs.filisova.template.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import rs.filisova.template.entity.OracleUserGrantEntity;

@Repository
public interface OracleUserGrantRepository extends JpaRepository<OracleUserGrantEntity, Long> {

    @Modifying
    @Query(value = "INSERT INTO oracle_users_grant (name, describe) VALUES (:name, :describe)", nativeQuery = true)
    void insertGrant(@Param("name") String name, @Param("describe") String describe);

    @Modifying
    @Query(value = "UPDATE oracle_users_grant SET name = :name, describe = :describe WHERE id = :id", nativeQuery = true)
    void updateGrant(@Param("id") Long id, @Param("name") String name, @Param("describe") String describe);
}
