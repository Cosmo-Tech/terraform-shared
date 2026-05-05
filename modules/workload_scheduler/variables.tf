variable "namespace" {
  type        = string
  description = "Kubernetes namespace where the scaler components are deployed"
  default     = "default"
}

variable "scaler_time_zone" {
  type        = string
  description = "Time zone used by the CronJobs for scheduling execution"
  default     = "Europe/Paris"
}

variable "scale_up_cron_schedule" {
  type        = string
  description = "Cron expression for scaling workloads up"
  default     = "0 09 * * 1-5"
}

variable "scale_down_cron_schedule" {
  type        = string
  description = "Cron expression for scaling workloads down"
  default     = "0 18 * * 1-5"
}

variable "enable_workload_scheduler" {
  type        = bool
  description = "Enable creation of workload scheduler resources"
}