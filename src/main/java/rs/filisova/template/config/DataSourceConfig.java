package rs.filisova.template.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.orm.jpa.EntityManagerFactoryBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.FilterType;
import org.springframework.context.annotation.Primary;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.EnableTransactionManagement;

import javax.sql.DataSource;
import java.util.Objects;

/**
 * Configuration for multiple datasources:
 * - PostgreSQL: Primary datasource with Liquibase support
 * - Oracle: Secondary datasource, managed via code only (NO Liquibase)
 */
@Slf4j
@Configuration
@EnableTransactionManagement
@EnableJpaRepositories(
        basePackages = "rs.filisova.template.repository",
        entityManagerFactoryRef = "postgresEntityManagerFactory",
        transactionManagerRef = "postgresTransactionManager",
        includeFilters = @ComponentScan.Filter(type = FilterType.REGEX, pattern = ".*Postgres.*Repository")
)
public class DataSourceConfig {

    /**
     * PostgreSQL DataSource Properties
     */
    @Primary
    @Bean(name = "postgresDataSourceProperties")
    @ConfigurationProperties("spring.datasource.postgres")
    public DataSourceProperties postgresDataSourceProperties() {
        return new DataSourceProperties();
    }

    /**
     * PostgreSQL DataSource - PRIMARY
     * Used by Liquibase for schema migrations
     */
    @Primary
    @Bean(name = "postgresDataSource")
    public DataSource postgresDataSource(
            @Qualifier("postgresDataSourceProperties") DataSourceProperties properties) {
        log.info("Configuring PostgreSQL datasource: {}", properties.getUrl());
        return properties.initializeDataSourceBuilder().build();
    }

    /**
     * PostgreSQL EntityManagerFactory
     */
    @Primary
    @Bean(name = "postgresEntityManagerFactory")
    public LocalContainerEntityManagerFactoryBean postgresEntityManagerFactory(
            EntityManagerFactoryBuilder builder,
            @Qualifier("postgresDataSource") DataSource dataSource) {
        return builder
                .dataSource(dataSource)
                .packages("rs.filisova.template.entity")
                .persistenceUnit("postgres")
                .build();
    }

    /**
     * PostgreSQL TransactionManager
     */
    @Primary
    @Bean(name = "postgresTransactionManager")
    public PlatformTransactionManager postgresTransactionManager(
            @Qualifier("postgresEntityManagerFactory") LocalContainerEntityManagerFactoryBean entityManagerFactory) {
        return new JpaTransactionManager(Objects.requireNonNull(entityManagerFactory.getObject()));
    }

    // ============================================
    // Oracle DataSource Configuration
    // NO LIQUIBASE - Manual management via code
    // ============================================

    /**
     * Oracle DataSource Properties
     */
    @Bean(name = "oracleDataSourceProperties")
    @ConfigurationProperties("spring.datasource.oracle")
    public DataSourceProperties oracleDataSourceProperties() {
        return new DataSourceProperties();
    }

    /**
     * Oracle DataSource - SECONDARY
     * NO Liquibase migrations, managed via code only
     */
    @Bean(name = "oracleDataSource")
    public DataSource oracleDataSource(
            @Qualifier("oracleDataSourceProperties") DataSourceProperties properties) {
        log.info("Configuring Oracle datasource: {}", properties.getUrl());
        log.warn("Oracle datasource configured WITHOUT Liquibase - schema management via code only");
        return properties.initializeDataSourceBuilder().build();
    }
}
