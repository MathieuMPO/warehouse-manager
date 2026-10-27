To setup flyway migrate :
    Setup flyway.conf
    Run -> Edit Configuration -> + -> Maven
    Name : Flyway Migrate
    Run : -Dflyway.configFiles=flyway.conf flyway:migrate