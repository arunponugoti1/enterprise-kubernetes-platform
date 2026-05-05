# Bootstrap starts with LOCAL state because it creates the bucket that holds remote state.
# After the first successful apply, uncomment the block below and run:
#   terraform init -migrate-state
#
# terraform {
#   backend "gcs" {
#     bucket = "REPLACE_WITH_state_bucket_OUTPUT"
#     prefix = "bootstrap"
#   }
# }
