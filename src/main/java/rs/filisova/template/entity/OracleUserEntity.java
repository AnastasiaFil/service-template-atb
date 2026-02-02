package rs.filisova.template.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Data;

import java.time.LocalDate;

@Data
@Entity
@Table(name = "oracle_users")
public class OracleUserEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    @Column(name = "birth_date_ora")
    private LocalDate birthDateOra;

    private String sex;

    @ManyToOne
    @JoinColumn(name = "role_id")
    private OracleUserRoleEntity role;

    @ManyToOne
    @JoinColumn(name = "grant_id")
    private OracleUserGrantEntity grant;
}
