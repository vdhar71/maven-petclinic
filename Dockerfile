FROM openjdk:17
EXPOSE 8080

RUN groupadd -r user && useradd -r -g user user
USER user

WORKDIR /app

COPY .mvn/ .mvn
COPY mvnw pom.xml ./
RUN ./mvnw dependency:resolve

COPY src ./src

CMD ["./mvnw", "spring-boot:run"]
