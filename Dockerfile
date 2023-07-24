FROM openjdk:17

EXPOSE 8080

RUN groupadd -r user && useradd -r -g user user
USER user

WORKDIR /app

COPY . /app

CMD ["./mvnw", "spring-boot:run"]
