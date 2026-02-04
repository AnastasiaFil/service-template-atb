package rs.filisova.template.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

import java.time.LocalDate;

@Data
@Entity
@Table(name = "postgres_users")
public class PostgresUserEntity {

    @Id
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column
    private String gender;

    @Column(nullable = false)
    private String role;

    @Column(name = "grant_field")
    private String grantField;
}
