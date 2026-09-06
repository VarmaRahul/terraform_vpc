variable "my_local_ip" {
  description = "The local IP address allowed to access the Kubernetes API"
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance size"
  type        = string
  default     = "t3.medium" # This acts as a fallback if you forget to set it
}