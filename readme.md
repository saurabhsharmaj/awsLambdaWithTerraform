Build Java Lambda JAR


mvn clean package
This produces target/xmlfeed-1.0.0.jar .

Create Lambda code S3 bucket (one-time)


aws s3 mb s3://my-lambda-code-bucket-xml-feed
Upload JAR to S3


aws s3 cp target/xmlfeed-1.0.0.jar s3://my-lambda-code-bucket-xml-feed/xmlfeed-1.0.0.jar
Run Terraform



terraform init
terraform apply