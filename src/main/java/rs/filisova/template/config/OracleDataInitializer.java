//package rs.filisova.template.config;
//
//import jakarta.annotation.PostConstruct;
//import lombok.extern.slf4j.Slf4j;
//import org.springframework.beans.factory.annotation.Qualifier;
//import org.springframework.context.annotation.Configuration;
//import org.springframework.core.io.ClassPathResource;
//import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
//
//import javax.sql.DataSource;
//
///**
// * Oracle Data Initializer
// * Automatically executes oracle-init.sql script on application startup
// */
//@Slf4j
//@Configuration
//public class OracleDataInitializer {
//
//    private final DataSource oracleDataSource;
//
//    public OracleDataInitializer(@Qualifier("oracleDataSource") DataSource oracleDataSource) {
//        this.oracleDataSource = oracleDataSource;
//    }
//
//    @PostConstruct
//    public void initializeOracleData() {
//        try {
//            log.info("Starting Oracle database initialization...");
//
//            ResourceDatabasePopulator populator = new ResourceDatabasePopulator();
//            populator.addScript(new ClassPathResource("oracle-init.sql"));
//            populator.setContinueOnError(false);
//            // Use / as separator for Oracle PL/SQL blocks and statements
//            populator.setSeparator("/");
//            populator.setBlockCommentStartDelimiter("/*");
//            populator.setBlockCommentEndDelimiter("*/");
//            populator.setCommentPrefixes("--");
//
//            populator.execute(oracleDataSource);
//
//            log.info("Oracle database initialization completed successfully");
//        } catch (Exception e) {
//            log.error("Failed to initialize Oracle database: {}", e.getMessage(), e);
//            throw new RuntimeException("Oracle database initialization failed", e);
//        }
//    }
//}
