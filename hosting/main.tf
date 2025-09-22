###############################################
# Weather Services
###############################################

provider "aws" {}

# API Gateway
resource "aws_api_gateway_rest_api" "my_api" {
  name = var.api_gateway_name
}

# API gateway proxy resource
resource "aws_api_gateway_resource" "my_api_resource" { # Create the {proxy+} resource under the root resource
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = "{proxy+}"
}

# API gateway proxy method
resource "aws_api_gateway_method" "my_api_method" { # Create the ANY method for the {proxy+} resource
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.my_api_resource.id
  http_method   = "ANY"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

###############################################

# App Runner
resource "aws_apprunner_service" "my_apprunner" {
  service_name = var.app_runner_name
  source_configuration {
    image_repository {
      image_identifier      = var.app_runner_image_arn
      image_repository_type = "ECR"
      image_configuration {
        port = "8080"
        runtime_environment_variables = {
          ASPNETCORE_ENVIRONMENT                         = "Production"
          AWS__CognitoConfiguration__UserPoolId          = var.app_runner_cognito_userpoolid
          AWS__ApiDataStreamingConfiguration__StreamName = var.app_runner_datastream_name
          Logging__LogLevel__Default                     = "Information"
          "Logging__LogLevel__Microsoft.AspNetCore"      = "Warning"
        }
        runtime_environment_secrets = {}
      }
    }
    auto_deployments_enabled = true
    authentication_configuration {
      access_role_arn = var.app_runner_access_role_arn
    }
  }
  instance_configuration {
    cpu               = "1024"
    memory            = "2048"
    instance_role_arn = var.app_runner_instance_role_arn
  }
  health_check_configuration {
    protocol            = "HTTP"
    path                = "/health"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 1
    unhealthy_threshold = 5
  }
  auto_scaling_configuration_arn = "arn:aws:apprunner:us-east-2:689502032294:autoscalingconfiguration/DefaultConfiguration/1/00000000000000000000000000000001"
  network_configuration {
    egress_configuration {
      egress_type = "DEFAULT"
    }
    ingress_configuration {
      is_publicly_accessible = false
    }
    ip_address_type = "IPV4"
  }
  observability_configuration {
    observability_enabled           = true
    observability_configuration_arn = "arn:aws:apprunner:us-east-2:689502032294:observabilityconfiguration/DefaultConfiguration/1/00000000000000000000000000000001"
  }
  tags = {
    Name    = var.app_runner_name
    AppName = var.application_name
  }
}

resource "aws_apprunner_vpc_ingress_connection" "my_apprunner_ingress" {
  name        = var.app_runner_ingress_name
  service_arn = aws_apprunner_service.my_apprunner.arn
  ingress_vpc_configuration {
    vpc_id          = var.vpc_id
    vpc_endpoint_id = var.vpc_endpoint_id
  }
  tags = {
    Name    = var.app_runner_ingress_name
    AppName = var.application_name
  }
}

resource "aws_api_gateway_integration" "my_api_integration" { # Integrate the ANY method with your VPC Link/NLB
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  resource_id             = aws_api_gateway_resource.my_api_resource.id
  http_method             = aws_api_gateway_method.my_api_method.http_method
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "https://${aws_apprunner_service.my_apprunner.service_url}/{proxy}"
  connection_type         = "VPC_LINK"
  connection_id           = var.api_vpc_link_id
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

resource "aws_api_gateway_method_response" "my_api_method_response" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.my_api_resource.id
  http_method = aws_api_gateway_method.my_api_method.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_deployment" "my_api_deployment" { # Deploy the API
  depends_on  = [aws_api_gateway_integration.my_api_integration]
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  triggers = { # Force a new deployment when any of these hashes change
    redeploy_hash = sha1(jsonencode([
      aws_api_gateway_method.my_api_method.id,
      aws_api_gateway_integration.my_api_integration.id,
      aws_api_gateway_method_response.my_api_method_response.id
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "my_api_stage" {
  stage_name    = "active"
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  deployment_id = aws_api_gateway_deployment.my_api_deployment.id
  #cache_cluster_enabled = true
  #cache_cluster_size    = "0.5"
}

# Custom domain API gateway mapping
resource "aws_api_gateway_base_path_mapping" "my_api_mapping" {
  api_id      = aws_api_gateway_rest_api.my_api.id
  stage_name  = aws_api_gateway_stage.my_api_stage.stage_name
  domain_name = var.api_domain_name
  base_path   = var.api_gateway_app_runner_base_path
}
