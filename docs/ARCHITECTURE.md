# Arquitectura — CIAD99

### Modelo (resumen)
- Catálogo/Seguridad: ciad99_usuarios, ciad99_clientes (>=100), ciad99_proveedores_operativos,
  ciad99_catalogo_aduanas, ciad99_catalogo_gastos_operativos, ciad99_configuracion
- Operación: ciad99_expedientes ({ADUANA}-{#####}-{AÑO}), ciad99_documentos, ciad99_observaciones
- Financiero: ciad99_anticipos, ciad99_anticipos_detalle, ciad99_solicitudes_anticipo,
  ciad99_solicitudes_anticipo_conceptos, ciad99_gastos_operativos, ciad99_facturacion,
  ciad99_facturacion_conceptos, ciad99_cuentas_por_cobrar
- Control: ciad99_bitacora, ciad99_notificaciones_enviadas

### Reglas
- Flujo de estados sin saltos.
- Anticipos múltiples; solicitudes {REF}-SA{NN}.
- Gastos permiten costo real (efectivo), precio cliente y utilidad.
- Bitácora obligatoria (quién/qué/cuándo).
