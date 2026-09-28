// Require the X-Ray SDK (need to install it first)
const AWSXRay = require("aws-xray-sdk-core");
const { S3Client, ListBucketsCommand } = require("@aws-sdk/client-s3");

// Require the AWS SDK v3 and capture it with X-Ray
const s3Client = AWSXRay.captureAWSv3Client(new S3Client());

exports.handler = async function (event) {
  const command = new ListBucketsCommand({});
  const response = await s3Client.send(command);

  return response;
};
