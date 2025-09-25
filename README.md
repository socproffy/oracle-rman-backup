# 🗄️ Oracle RMAN Backup - KornShell Script (10g → 23ai)

Este repositorio contiene un script hecho en KornShell (ksh) que actúa como wrapper de RMAN para estandarizar y automatizar backups de Oracle Database, originalmente desarrollado en 2008 (Oracle 10g, UNIX) y actualizado para su uso en Oracle Database 23ai y entornos modernos.

Gracias a su diseño modular y a la simplicidad de parámetros, a partir de aquí resulta muy sencillo automatizarlo en cualquier plataforma del mercado (on-premises o cloud) e integrarlo en planificadores como cron, systemd, Oracle Scheduler o gestores corporativos de jobs de cualquier software del mercado.

Esto permite maximizar los beneficios del uso de los backups en diferentes escenarios: desde la protección de sistemas Base, hasta la habilitación de entornos de pruebas, desarrollo, reporting o replicación, aprovechando toda la potencia de los sistemas operativos basados en UNIX (Linux, AIX, Solaris, HP-UX, etc.) en cualquier infraestructura, incluyendo plataformas de última generación como Oracle Exadata.

⚡CONTACTE SI QUIERE LA SOLUCIÓN ADAPTADA CON PLANES DE RECUPERACIÓN.
⚡TIEMPOS DE RECUPERACIÓN PUEDEN VARIAR SEGÚN EL ENTORNO.
⚡HABLE PARA HACER PRUEBAS REGULARES Y AUDITORÍAS DE SEGUIMIENTO.

---

## 👤 Autoría

- **Autor:** Ollear Mena López  
- **Empresa:** ELITEDATA S.L.  
- 🌐 [csgelitedata.com](https://csgelitedata.com)  

---

## 📖 Descripción

El script `rman_backup_legacy10g_to_23ai.sh`:
- Captura el *profile* de la instancia Oracle (`.profile_<SID>`).  
- Valida que la instancia está en estado `OPEN`.  
- Ejecuta backups **full / incremental** sobre **database** o **tablespace**.  
- Permite destino en **DISCO** o **CINTA (MML)** según sufijo `*_to_disk` o `*_to_tape`.  
- Aplica políticas de retención compatibles con RMAN y `CONTROL_FILE_RECORD_KEEP_TIME`.  
- Solo debe ejecutarse con el usuario de sistema operativo `oracle` (dueño del software de Oracle).

### Parámetros
1. **SID** de la instancia.  
2. **Tipo de backup** (10 opciones disponibles, ver tabla).  
3. **Ruta en disco** (si aplica).  
4. **Nombre del tablespace** (si aplica).  

### Tipos de backup soportados
| Opción | Descripción |
|--------|-------------|
| `database_base_to_disk` | Backup inicial completo a disco (obligatorio). |
| `database_base_to_tape` | Backup inicial completo a cinta (obligatorio). |
| `full_database_to_disk` | Level 0 + archivelogs a disco (requiere base previa). |
| `full_database_to_tape` | Level 0 + archivelogs a cinta (requiere base previa). |
| `incremental_database_to_disk` | Level 1 a disco (requiere full previo). |
| `incremental_database_to_tape` | Level 1 a cinta (requiere full previo). |
| `full_tablespace_to_disk` | Level 0 de un tablespace a disco. |
| `full_tablespace_to_tape` | Level 0 de un tablespace a cinta. |
| `incremental_tablespace_to_disk` | Level 1 de un tablespace a disco (requiere full previo). |
| `incremental_tablespace_to_tape` | Level 1 de un tablespace a cinta (requiere full previo). |

---

## ⚡ Ejemplos de ejecución


* Backup base a disco: 

 ```bash
 ./backup_rman.sh <SID> database_base_to_disk /backup/path
 ```
* Backup base a cinta:

  ```bash
  ./backup_rman.sh <SID> database_base_to_tape
  ```
* Backup full level 0 a disco:

  ```bash
  ./backup_rman.sh <SID> full_database_to_disk /backup/path
  ```
* Backup full tablespace a disco:

  ```bash
  ./backup_rman.sh <SID> full_tablespace_to_disk /backup/path USERS
  ```
* Backup incremental level 1 a cinta:

  ```bash
  ./backup_rman.sh <SID> incremental_database_to_tape
  ```

## 🔧 Mejoras modernas (comentadas en el script)

* **Multitenant (CDB/PDB).**
* **Compresión.**
* **Paralelismo.**
* **Destinos cloud (OCI, AWS, Azure, GCP, ZDLRA, MML).**
* **Logging mejorado.**

---

## 📜 Licencia

Este repositorio se distribuye bajo la licencia MIT.
Puedes usarlo, modificarlo y compartirlo libremente, siempre que mantengas este aviso de autoría.

---

