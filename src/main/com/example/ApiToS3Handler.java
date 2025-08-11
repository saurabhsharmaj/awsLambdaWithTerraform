package com.example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Instant;

public class ApiToS3Handler implements RequestHandler<Object, String> {

    private static final String BUCKET_NAME = System.getenv("BUCKET_NAME");
    private static final String API_URL = System.getenv("API_URL");

    @Override
    public String handleRequest(Object input, Context context) {
        try {
            // Call REST API
            HttpClient client = HttpClient.newHttpClient();
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(API_URL))
                    .GET()
                    .build();

            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() != 200) {
                throw new RuntimeException("Failed API call: " + response.statusCode());
            }

            String keyName = "api-response-" + Instant.now() + ".json";

            // Upload to S3
            S3Client s3 = S3Client.create();
            s3.putObject(
                    PutObjectRequest.builder()
                            .bucket(BUCKET_NAME)
                            .key(keyName)
                            .build(),
                    RequestBody.fromString(response.body(), StandardCharsets.UTF_8)
            );

            return "Stored in S3: " + keyName;
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}