#!/usr/bin/env bash
# Ejecuta una consulta en Athena, descarga su resultado y registra la ejecución.
# Uso: bash scripts/ejecutar_athena.sh <etapa> <archivo_sql> <archivo_resultado> [numero_consulta]
set -euo pipefail
etapa=$1; sql=$2; destino=$3; numero=${4:-1}
cd "$(dirname "$0")/.."
workgroup=$(terraform -chdir=infraestructura output -raw workgroup_athena)
base=$(terraform -chdir=infraestructura output -raw base_datos_glue)
consulta=$(python3 - "$sql" "$numero" <<'PY'
import sys
texto = open(sys.argv[1], encoding="utf-8").read()
lineas = [l for l in texto.splitlines() if not l.strip().startswith("--")]
partes = [p.strip() for p in "\n".join(lineas).split(";") if p.strip()]
print(partes[int(sys.argv[2]) - 1])
PY
)
id=$(aws athena start-query-execution --work-group "$workgroup" \
      --query-execution-context Database="$base" --query-string "$consulta" \
      --query QueryExecutionId --output text)
echo "Ejecución: $id"
while true; do
  estado=$(aws athena get-query-execution --query-execution-id "$id" --query QueryExecution.Status.State --output text)
  case "$estado" in
    SUCCEEDED) break ;;
    FAILED|CANCELLED)
      aws athena get-query-execution --query-execution-id "$id" --query QueryExecution.Status.StateChangeReason --output text
      exit 1 ;;
  esac
  sleep 1
done
salida=$(aws athena get-query-execution --query-execution-id "$id" --query QueryExecution.ResultConfiguration.OutputLocation --output text)
mkdir -p "$(dirname "$destino")"
aws s3 cp "$salida" "$destino" --only-show-errors
registro=evidencias/ejecuciones_athena.csv
[ -f "$registro" ] || echo "etapa,archivo_sql,id_ejecucion,archivo_resultado" > "$registro"
echo "$etapa,$sql,$id,$destino" >> "$registro"
cat "$destino"
