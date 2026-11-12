output "bucket" {
  description = "Bucket S3 del ejercicio"
  value       = aws_s3_bucket.datos.bucket
}

output "base_datos_glue" {
  description = "Base de datos de Glue Data Catalog"
  value       = aws_glue_catalog_database.entregas.name
}

output "tabla_glue" {
  description = "Tabla externa con partition projection"
  value       = aws_glue_catalog_table.entregas.name
}

output "workgroup_athena" {
  description = "Workgroup de Athena"
  value       = aws_athena_workgroup.entregas.name
}

output "ubicacion_resultados_athena" {
  description = "Prefijo donde Athena escribe los resultados"
  value       = "s3://${aws_s3_bucket.datos.bucket}/resultados-athena/"
}
