# generate root access keys
aws configure --profile root-mfa-delete-demo

# enable mfa delete
aws s3api put-bucket-versioning --bucket demo-minhphamuit91-mfa-delete --versioning-configuration Status=Enabled,MFADelete=Enabled --mfa "arn:aws:iam::037918102102:mfa/Authapp mfa-code" --profile root
# disable mfa delete
aws s3api put-bucket-versioning --bucket demo-minhphamuit91-mfa-delete --versioning-configuration Status=Enabled,MFADelete=Disabled --mfa "arn:aws:iam::037918102102:mfa/Authapp mfa-code" --profile root

# delete the root credentials in the IAM console!!!