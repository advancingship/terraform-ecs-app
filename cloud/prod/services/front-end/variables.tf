# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ---------------------------------------------------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# Parameters in all uppercase refer to environmental variables prefixed with: TF_VAR_
#     Example:
#         linux environmental variable command: export TF_VAR_PROJECT_1_NAME="project-one"
#         corresponds with code below: varable "PROJECT_1_NAME" { ... }
#         subsequently assigning that variable the value: "project-one"
# ---------------------------------------------------------------------------------------------------------------------

variable "PROJECT_1_NAME" {
  type	      = string
  default     = "name-default"
}

variable "PROJECT_1_WORKING_DIRECTORY" {
  type        = string
  default     = "/home/directory-default"
}

variable "PROJECT_1_KEY_NAME" {
  type        = string
  default     = "key-name-default"
}

variable "PROJECT_1_IMAGE_URI" {	
  type        = string
  default     = "some-repository.com/image-default:latest"
}

variable "PROJECT_1_AWS_REGION_1" {
  description = "aws deployment region"
  type	      = string
  default     = "us-east-2"
}

variable "task_name" {
  description = "The name to set for the ECS task."
  type        = string
  default     = "task-default"
}

