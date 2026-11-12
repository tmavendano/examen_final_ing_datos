# Punto 2: consulta de entregas con Athena y partition projection

Autor: Tomás Avendaño Parra

Infraestructura en AWS, creada con Terraform, para consultar con Athena los archivos diarios de intentos de entrega. Las fechas nuevas se consultan sin crawlers ni registro manual de particiones, gracias a partition projection.

## Arquitectura

```text
CSV locales ──► S3: entregas/fecha=yyyy-MM-dd/entregas.csv
                    │
                    ▼
     Glue Data Catalog: tabla externa entregas_db.entregas
     (esquema + reglas de partition projection)
                    │
                    ▼
     Athena (workgroup entregas_wg) ──► S3: resultados-athena/
```

| Recurso | Nombre |
| --- | --- |
| Bucket S3 privado | `de-final-entregas-tomas-20261112` |
| Base de datos de Glue | `entregas_db` |
| Tabla externa | `entregas` |
| Workgroup de Athena | `entregas_wg` |
| Región | `us-east-1` |

## Prerrequisitos

- Terraform 1.5 o superior (se usó 1.9.8) y proveedor `hashicorp/aws` 5.x (se instaló 5.100.0).
- AWS CLI v2 (se usó 2.36) con credenciales configuradas (`aws configure`) y región `us-east-1`.
- Python 3 (se usó 3.12) para el script de consultas y la comparación de resultados.
- Un usuario IAM con permisos sobre S3, Glue y Athena. Al usuario `user_cli` se le agregaron las políticas administradas `AmazonAthenaFullAccess` y `AWSGlueConsoleFullAccess` (ver "Incidencias"). En un entorno real se usaría una política con permisos mínimos.

Verificación de credenciales y región:

```bash
aws sts get-caller-identity
aws configure set region us-east-1
aws configure get region
```

## Estructura

```text
infraestructura/        principal.tf, variables.tf, salidas.tf
consultas/              SQL de la demostración inicial y de la verificación del tercer día
scripts/                ejecutar_athena.sh: ejecuta una consulta, descarga el resultado y registra el ID
resultados/             resultados obtenidos en Athena (inicial/ y final/)
evidencias/             apply, outputs, registro de ejecuciones de Athena y destroy
data/                   CSV de entrada suministrados (sin modificar)
resultados_esperados/   referencias suministradas
ENUNCIADO.md            enunciado original del punto
```

## Configuración

Las variables están en `infraestructura/variables.tf` y todas tienen valor por defecto: región, nombre del bucket, base de datos, tabla, workgroup y rango de fechas (`2026-10-01` a `2026-10-03`). El nombre del bucket debe ser único en AWS. Para reproducir el ejercicio con otro nombre se puede usar `-var "nombre_bucket=otro-nombre"`.

La tabla usa `LazySimpleSerDe` con separador coma y `skip.header.line.count = 1`. Declara las cinco columnas en el orden del archivo (`id_envio`, `ciudad`, `transportadora`, `estado` como `string` y `duracion_minutos` como `int`) y `fecha` como clave de partición `string`. Las propiedades de proyección son:

| Propiedad | Valor |
| --- | --- |
| `projection.enabled` | `true` |
| `projection.fecha.type` | `date` |
| `projection.fecha.format` | `yyyy-MM-dd` |
| `projection.fecha.range` | `2026-10-01,2026-10-03` |
| `projection.fecha.interval` | `1` |
| `projection.fecha.interval.unit` | `DAYS` |
| `storage.location.template` | `s3://<bucket>/entregas/fecha=${fecha}/` |

## Despliegue

```bash
cd infraestructura
terraform init
terraform validate
terraform plan
terraform apply -auto-approve -no-color 2>&1 | tee ../evidencias/aplicacion_terraform.txt
terraform state list | tee -a ../evidencias/aplicacion_terraform.txt
terraform output -json > ../evidencias/outputs.json
cd ..
```

## Etapa inicial: días 1 y 2

Se cargan solo dos archivos, uno por uno:

```bash
BUCKET=$(terraform -chdir=infraestructura output -raw bucket)
aws s3 cp "data/entregas/fecha=2026-10-01/entregas.csv" "s3://$BUCKET/entregas/fecha=2026-10-01/entregas.csv"
aws s3 cp "data/entregas/fecha=2026-10-02/entregas.csv" "s3://$BUCKET/entregas/fecha=2026-10-02/entregas.csv"
aws s3 ls "s3://$BUCKET/entregas/" --recursive
```

Las consultas se ejecutan en el workgroup con `scripts/ejecutar_athena.sh <etapa> <sql> <resultado> [numero_consulta]`. El script lanza la consulta, espera a que termine, descarga el CSV que Athena dejó en `resultados-athena/` y agrega una fila a `evidencias/ejecuciones_athena.csv`.

```bash
bash scripts/ejecutar_athena.sh inicial consultas/intentos_por_fecha_estado.sql resultados/inicial/intentos_por_fecha_estado.csv
bash scripts/ejecutar_athena.sh inicial consultas/porcentaje_exito_por_fecha_ciudad.sql resultados/inicial/porcentaje_exito_por_fecha_ciudad.csv
bash scripts/ejecutar_athena.sh inicial consultas/duracion_promedio_2026-10-02.sql resultados/inicial/duracion_promedio_2026-10-02.csv
bash scripts/ejecutar_athena.sh inicial consultas/conteo_total.sql resultados/inicial/conteo_total.csv
```

Resultado: 12 registros consultables. Las tres consultas coinciden con `resultados_esperados/intentos_por_fecha_estado_inicial.csv`, `resultados_esperados/porcentaje_exito_por_fecha_ciudad_inicial.csv` y `resultados_esperados/duracion_promedio_2026-10-02.csv`.

Notas sobre el SQL:

- El porcentaje usa `100.0E0` (un double) para evitar la división entera, y `CAST(ROUND(x, 2) AS DECIMAL(5,2))` para conservar dos decimales.
- El promedio filtra `estado = 'entregado'`, así que los ceros de los intentos fallidos no entran en el cálculo.
- Las consultas de intentos y porcentaje no filtran por fecha. Por eso incluyen el día 3 sin cambiar el SQL.

## Etapa final: incorporación del día 3

Solo se sube el archivo y se consulta. No se ejecutaron crawlers, `MSCK REPAIR TABLE` ni `ALTER TABLE ADD PARTITION`, y no se cambió la tabla ni el código Terraform.

```bash
aws s3 cp "data/entregas/fecha=2026-10-03/entregas.csv" "s3://$BUCKET/entregas/fecha=2026-10-03/entregas.csv"
bash scripts/ejecutar_athena.sh final consultas/verificacion_tercer_dia.sql resultados/final/verificacion_tercer_dia.csv 1
bash scripts/ejecutar_athena.sh final consultas/verificacion_tercer_dia.sql resultados/final/verificacion_tercer_dia_conteo_estados.csv 2
bash scripts/ejecutar_athena.sh final consultas/verificacion_tercer_dia.sql resultados/final/verificacion_tercer_dia_total.csv 3
bash scripts/ejecutar_athena.sh final consultas/intentos_por_fecha_estado.sql resultados/final/intentos_por_fecha_estado.csv
bash scripts/ejecutar_athena.sh final consultas/porcentaje_exito_por_fecha_ciudad.sql resultados/final/porcentaje_exito_por_fecha_ciudad.csv
```

Resultado:

- 6 registros del 3 de octubre (`ENV-013` a `ENV-018`).
- Conteo por estado del 3 de octubre: 3 `destinatario_ausente`, 1 `direccion_incorrecta` y 2 `entregado`.
- 18 registros en total en la tabla.
- Las consultas de intentos y porcentaje coinciden con `resultados_esperados/intentos_por_fecha_estado_final.csv` y `resultados_esperados/porcentaje_exito_por_fecha_ciudad_final.csv`.

El promedio de duración sigue correspondiendo al día 2 y mantiene la misma referencia.

## Comparación con las referencias

Athena escribe cada valor entre comillas. La comparación lee ambos archivos como CSV y compara valor por valor:

```bash
python3 - <<'PY'
import csv
pares = [
    ("resultados/final/intentos_por_fecha_estado.csv", "resultados_esperados/intentos_por_fecha_estado_final.csv"),
    ("resultados/final/porcentaje_exito_por_fecha_ciudad.csv", "resultados_esperados/porcentaje_exito_por_fecha_ciudad_final.csv"),
]
for obtenido, esperado in pares:
    a = list(csv.reader(open(obtenido, encoding="utf-8")))
    b = list(csv.reader(open(esperado, encoding="utf-8")))
    print("COINCIDE  " if a == b else "DIFERENTE ", obtenido)
PY
```

## Registro de ejecuciones

`evidencias/ejecuciones_athena.csv` relaciona cada ejecución con su etapa (`inicial` o `final`), el archivo SQL, el ID de ejecución de Athena y el archivo de resultado. Las rutas son relativas a la raíz del repositorio.

## Limpieza

Primero se guardan todas las evidencias. Luego:

```bash
terraform -chdir=infraestructura destroy -auto-approve -no-color 2>&1 | tee evidencias/eliminacion_terraform.txt
```

El bucket y el workgroup tienen `force_destroy = true`, así que `destroy` vacía el bucket (CSV y resultados de Athena) antes de eliminar los recursos. Se eliminan los cinco recursos del punto: bucket, bloqueo de acceso público, base de datos, tabla y workgroup.

## Incidencias

El primer `terraform apply` creó el bucket y el bloqueo de acceso público, pero falló en Glue (`glue:CreateDatabase`) y en Athena (`athena:CreateWorkGroup`) por falta de permisos de `user_cli`. Se agregaron las políticas indicadas en "Prerrequisitos" desde la consola de IAM y se repitió `terraform apply`, que creó solo los recursos que faltaban. La salida del primer intento está en `evidencias/aplicacion_terraform_intento1_sin_permisos.txt`. El archivo `evidencias/aplicacion_terraform.txt` termina con `terraform state list`, que muestra los cinco recursos.

No se publican credenciales ni archivos de estado de Terraform: `.gitignore` excluye `.terraform/`, `*.tfstate*`, `*.tfvars` y archivos de credenciales.
