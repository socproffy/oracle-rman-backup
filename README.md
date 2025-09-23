# 🗄️ Oracle RMAN Backup Script (10g → 23ai)

Este repositorio contiene un **script shell (ksh)** que actúa como wrapper de **RMAN** para estandarizar y automatizar backups de **Oracle Database**, originalmente desarrollado en 2008 (Oracle 10g, UNIX) y actualizado en 2025 para su uso en **Oracle Database 23ai** y entornos modernos.

---

## 👤 Autoría

- **Autor:** Ollear Mena López  
- **Empresa:** ELITEDATA S.L.  
- 🌐 [csgelitedata.com](https://csgelitedata.com)  

---

## 📖 Descripción

El script `backup_rman.sh`:
- Captura el *profile* de la instancia Oracle (`.profile_<SID>`).  
- Valida que la instancia está en estado `OPEN`.  
- Ejecuta backups **full / incremental** sobre **database** o **tablespace**.  
- Permite destino en **DISCO** o **CINTA (MML)** según sufijo `*_to_disk` o `*_to_tape`.  
- Aplica políticas de retención compatibles con RMAN y `CONTROL_FILE_RECORD_KEEP_TIME`.  
- Solo debe ejecutarse con el usuario de sistema operativo `oracle`.

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
---

* Backup base a disco:  
  ```bash
  ./backup_rman.sh <SID> database_base_to_disk /backup/path
````
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
---

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
