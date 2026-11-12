variable "region" {
  description = "Región de AWS donde se crean los recursos"
  type        = string
  default     = "us-east-1"
}

variable "nombre_bucket" {
  description = "Nombre del bucket S3 (único en todo AWS, minúsculas)"
  type        = string
  default     = "de-final-entregas-tomas-20261112"
}

variable "nombre_base_datos" {
  description = "Base de datos de Glue Data Catalog"
  type        = string
  default     = "entregas_db"
}

variable "nombre_tabla" {
  description = "Tabla externa de entregas"
  type        = string
  default     = "entregas"
}

variable "nombre_workgroup" {
  description = "Workgroup de Athena para el ejercicio"
  type        = string
  default     = "entregas_wg"
}

variable "fecha_inicio" {
  description = "Primera fecha proyectada (incluida)"
  type        = string
  default     = "2026-10-01"
}

variable "fecha_fin" {
  description = "Última fecha proyectada (incluida)"
  type        = string
  default     = "2026-10-03"
}
