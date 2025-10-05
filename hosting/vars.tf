###############################################
# Environment
###############################################

variable "project_name" {
  type    = string
  default = "Curtis Lawhorn"
}

###############################################
# API Gateway
###############################################

variable "api_gateway_name" {
  type    = string
  default = "curtislawhorn-weatherservices-api"
}

variable "api_vpc_link_id" {
  type    = string
  default = "ptb6pl"
}

variable "api_domain_name" {
  type    = string
  default = "api.curtislawhorn.com"
}

variable "api_gateway_app_runner_base_path" {
  type    = string
  default = "weather-services"
}

###############################################
# App Runner
###############################################

variable "app_runner_name" {
  type    = string
  default = "curtislawhorn-weather-services"
}

variable "app_runner_cognito_userpoolid" {
  type    = string
  default = "us-east-2_DHhagrvR2"
}

variable "app_runner_datastream_name" {
  type    = string
  default = "curtislawhorn-weatherservices-stream"
}

variable "app_runner_image_arn" {
  type    = string
  default = "689502032294.dkr.ecr.us-east-2.amazonaws.com/leakycauldron/recipe-services:latest"
}

variable "app_runner_access_role_arn" {
  type    = string
  default = "arn:aws:iam::689502032294:role/service-role/AppRunnerECRAccessRole"
}

variable "app_runner_instance_role_arn" {
  type    = string
  default = "arn:aws:iam::689502032294:role/AppRunnerSecurityAccessRole"
}

variable "app_runner_ingress_name" {
  type    = string
  default = "curtislawhorn-weatherservices-ingress"
}

variable "vpc_id" {
  type    = string
  default = "vpc-0ba992ff6a2a453e6"
}

variable "vpc_endpoint_id" {
  type    = string
  default = "vpce-02d6832ed6e59e967"
}