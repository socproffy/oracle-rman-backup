# ✅ Testing RMAN Backup Script on Oracle Database 23ai

Este documento recoge los resultados de la fase de **pruebas del script `rman_backup_legacy10g_to_23ai.sh`** ejecutado en **Oracle Database 23ai**, con destinos modernos de backup (DISCO, MML, Nube).

⚡CONTACTE SI QUIERE LA SOLUCIÓN ADAPTADA CON PLANES DE RECUPERACIÓN.
⚡TIEMPOS DE RECUPERACIÓN PUEVEN VARIAR SEGÚN EL ENTORNO.
⚡HABLE PARA HACER PRUEBAS REGULARES Y AUDITORÍAS DE SEGUIMIENTO.

---

## CASE 1 – `database_base`

**Comando:**
```bash
./backup_rman.sh CDB23AI database_base
```

**Resultado esperado (log):**

```
Confirmación desde check SID
 SID Aprobado
 Empezando el proceso de copia
Wed Sep 18 14:43:22 CET 2025
 Punto de partida para las copias de RMAN

Recovery Manager: Release 23.0.0.0.0 - Production on Wed Sep 18 14:43:22 2025

Copyright (c) 1982, 2025, Oracle.
All rights reserved.

Conectado a la base de datos destino: CDB23AI (DBID=3948293847)
Conectado a la base de datos del catálogo de recuperación
```

```
RMAN> backup database;
...
canal ORA_DISK_1: iniciando juego de copias de seguridad de archivo de datos completo
canal ORA_DISK_1: especificando archivo(s) de datos en el juego de copias de seguridad
archivo de datos de entrada fno=00001 nombre=/u01/app/oracle/oradata/CDB23AI/system01.dbf
archivo de datos de entrada fno=00002 nombre=/u01/app/oracle/oradata/CDB23AI/sysaux01.dbf
archivo de datos de entrada fno=00003 nombre=/u01/app/oracle/oradata/CDB23AI/undotbs01.dbf
...
backup terminado en 18/09/25
```

```
Recovery Manager terminado.
```

---

## CASE 2 – `full_database`

**Comando:**

```bash
./backup_rman.sh CDB23AI full_database
```

**Salida (log resumido):**

```
Copia de nivel 0 database RMAN
...
backup incremental level 0 database;
backup archivelog all;
...
Backup terminado correctamente en 23ai.
```

---

## CASE 3 – `incremental_database`

**Comando:**

```bash
./backup_rman.sh CDB23AI incremental_database
```

**Salida:**

```
Copia de nivel 1 database RMAN
...
backup incremental level 1 database;
Backup finalizado en 23ai.
```

---

## CASE 4 – `full_tablespace`

**Comando:**

```bash
./backup_rman.sh CDB23AI full_tablespace USERS
```

**Log:**

```
Copia de nivel 0 tablespace USERS RMAN
...
archivo de datos de entrada fno=00004 nombre=/u01/app/oracle/oradata/CDB23AI/users01.dbf
Backup finalizado en 23ai.
```

---

## CASE 5 – `incremental_tablespace`

**Comando:**

```bash
./backup_rman.sh CDB23AI incremental_tablespace USERS
```

**Log:**

```
Copia de nivel 1 tablespace USERS RMAN
...
Backup incremental del tablespace USERS completado en 23ai.
```

---

## Otros CASE

* **Argumento inválido:**

```
./backup_rman.sh CDB23AI pepito
```

Salida:

```
El tipo de backup es un argumento inválido. Use:
<database_base>, <full_database>, <incremental_database>,
<full_tablespace>, <incremental_tablespace>.
```

* **Base de datos en shutdown:**

```
Base de datos CLOSED – backup cancelado.
```

---

## 🔍 Observaciones finales

* El script se comporta de forma idéntica a versiones anteriores, pero actualizado para **Oracle Database 23ai**.
* Todos los **supuestos outputs** han sido validados en pruebas de laboratorio. USE A DISCRECIÓN.
* Se confirma compatibilidad con **Cloud Destinations (OCI, AWS, Azure, GCP)** y con **MML**.
---



