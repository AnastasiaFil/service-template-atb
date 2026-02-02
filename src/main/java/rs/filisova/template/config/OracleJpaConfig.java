package rs.filisova.template.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.orm.jpa.EntityManagerFactoryBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.FilterType;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.transaction.PlatformTransactionManager;

import javax.sql.DataSource;
import java.util.Objects;

/**
 * Oracle JPA Configuration
 * Separate repository package for Oracle entities
 * NO Liquibase - schema managed via code only
 */
@Slf4j
@Configuration
@EnableJpaRepositories(
        basePackages = "rs.filisova.template.repository",
        entityManagerFactoryRef = "oracleEntityManagerFactory",
        transactionManagerRef = "oracleTransactionManager",
        includeFilters = @ComponentScan.Filter(type = FilterType.REGEX, pattern = ".*Oracle.*Repository")
)
public class OracleJpaConfig {

    /**
     * Oracle EntityManagerFactory
     */
    @Bean(name = "oracleEntityManagerFactory")
    public LocalContainerEntityManagerFactoryBean oracleEntityManagerFactory(
            EntityManagerFactoryBuilder builder,
            @Qualifier("oracleDataSource") DataSource dataSource) {
        log.info("Configuring Oracle EntityManagerFactory");
        
        // Oracle-specific properties - disable default schema
        java.util.Map<String, Object> properties = new java.util.HashMap<>();
        properties.put("hibernate.default_schema", ""); // No default schema for Oracle
        
        return builder
                .dataSource(dataSource)
                .packages("rs.filisova.template.entity")
                .persistenceUnit("oracle")
                .properties(properties)
                .build();
    }

    /**
     * Oracle TransactionManager
     */
    @Bean(name = "oracleTransactionManager")
    public PlatformTransactionManager oracleTransactionManager(
            @Qualifier("oracleEntityManagerFactory") LocalContainerEntityManagerFactoryBean entityManagerFactory) {
        return new JpaTransactionManager(Objects.requireNonNull(entityManagerFactory.getObject()));
    }
}
