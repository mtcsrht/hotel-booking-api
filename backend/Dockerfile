FROM eclipse-temurin:25-jdk AS build
WORKDIR /app
COPY .mvn .mvn
COPY mvnw pom.xml ./
COPY src src
RUN --mount=type=cache,target=/root/.m2 ./mvnw -B -q -DskipTests package

FROM eclipse-temurin:25-jre
COPY --from=build /app/target/*.jar /app.jar
USER 1000
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app.jar"]
