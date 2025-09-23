#!/bin/ksh
umask 077
fecha="`date '+%Y%m%d'" 

##### Comprobación y carga de las variables de entorno de la instancia para el backup ....
. $HOME/bin/.profile_$1

#####Cargando las variables del script ....
LOGFILE=/data/oradb01/oradmp/rman_Backup_${fecha}.log
BCKSCRIPT=/data/oradb01/oradmp/rman.rman
export LOGFILE BCKSCRIPT

####################################################################################################
# [NUEVO - COMENTADO] OPCIONES DE LOGGING MEJORADO (sin modificar tu flujo actual)
# Sugerencia: activar tracing del shell y enviar salida simultánea al LOG con 'tee'
# set -o errexit -o pipefail -o nounset   # Fail fast (recomendado en 23ai)
# exec > >(tee -a "$LOGFILE") 2>&1        # Duplicar salida a pantalla + log
# PS4='+ $(date "+%F %T") pid=$$ '        # Prefijo con timestamp en xtrace
# set -o xtrace                           # Trazar comandos (útil para depuración)
####################################################################################################

####################################################################################################
# [NUEVO - COMENTADO] 34 RUTAS / DESTINOS DE BACKUP MODERNOS (DISCO/OBJETO/NUBE/MML)
# Usa estos ejemplos como valor de la variable 'disk' (tercer parámetro) cuando corresponda.
#  1)  /u01/backup
#  2)  /backup/local-ssd
#  3)  /mnt/nvme/backup
#  4)  /data/backup
#  5)  /opt/backups
#  6)  /backups/NFS/share1
#  7)  /backups/NFS/share2
#  8)  /mnt/san/oracle_backup
#  9)  /mnt/isilon/oracle
# 10)  /mount/netapp/backup
# 11)  /mount/dellemc/powerstore/ora
# 12)  /mount/hpe/3par/ora_bkp
# 13)  /mnt/ceph/ora_backup
# 14)  /mnt/gluster/ora_backup
# 15)  /mnt/minio/s3/ora_backup                 # S3-compatible on-prem (MinIO)
# 16)  /mnt/oci/objectstorage/fuse/ora_backup    # Oracle Cloud Storage (FUSE)  [Oracle Cloud Storage BLOB/OCI]
# 17)  oci://bucket@namespace/ora_backup         # URI lógico (con OSB Cloud/DBB); vía SBT/Cloud Module
# 18)  s3://aws-bucket/ora_backup                # AWS S3 (EC2/AWS) con gateway o plugin
# 19)  /mnt/aws/efs/ora_backup                   # AWS EFS montado
# 20)  /mnt/azure/blobfuse/container/ora_backup  # Azure Blob con blobfuse
# 21)  wasbs://container@account.blob.core.windows.net/ora_backup  # Azure Blob (URI)
# 22)  /mnt/azure/files/ora_backup               # Azure Files (SMB/NFS)
# 23)  gs://gcp-bucket/ora_backup                # Google Cloud Storage (GCS)
# 24)  /mnt/gcp/filestore/ora_backup             # Google Filestore (NFS)
# 25)  /mnt/ibm/cos/ora_backup                   # IBM Cloud Object Storage
# 26)  /mnt/alibaba/oss/ora_backup               # Alibaba Cloud OSS
# 27)  /mnt/ovh/s3/ora_backup                    # OVH Object Storage (S3)
# 28)  /mnt/backblaze/b2/ora_backup              # Backblaze B2
# 29)  /mnt/wasabi/s3/ora_backup                 # Wasabi (S3)
# 30)  /mnt/vastdata/ora_backup                  # VAST Data
# 31)  /mnt/qnap/nfs/ora_backup                  # QNAP NFS
# 32)  /mnt/synology/nfs/ora_backup              # Synology NFS
# 33)  /mnt/veritas/netbackup/stage              # Stage local para MML (NetBackup)
# 34)  # MML (Media Management Layer) directo:
#      #   export SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64   # Ej. Veritas NetBackup
#      #   export NB_ORA_SERV=netbackup-master.example               # Variables específicas del MML
#      #   export NB_ORA_POLICY=ORA_POLICY                           # Ajustar a tu entorno
####################################################################################################

#####Comprobación efectiva del estado de la base de datos y la instancia actual para el backup ....
db_status=`sqlplus -s "/ as sysdba" <<EOF
set heading off
set feedback off
set verify off
select status from v\\$instance;
exit
EOF
`

####################################################################################################
# [NUEVO - COMENTADO] SOPORTE MULTITENANT (CDB/PDB)
# Si tu BD es CDB y quieres operar sobre una PDB concreta, puedes:
#  - Ajustar el contexto SQLPlus antes de los queries:
#    sqlplus -s "/ as sysdba" <<EOF
#    alter session set container=PDB1;
#    <tu SQL aquí>
#    EOF
#
#  - O dentro de RMAN, ejecutar un SQL para fijar el contenedor:
#    RMAN> sql "alter session set container=PDB1";
#
#  - Para entornos con múltiples PDBs, parametriza la PDB:
#    PDB_NAME="${5:-PDB1}"   # (comentado: quinto parámetro opcional)
#    # y luego dentro de cada bloque RMAN:
#    # sql "alter session set container=${PDB_NAME}";
####################################################################################################

(if [ $db_status = "OPEN" ]; then
check_SID=`sqlplus -s "/ as sysdba" <<EOF
set heading off
set feedback off
set verify off
select instance_name from v\\$instance;
exit
EOF
`
echo " Confirmación desde check SID "
if [ $check_SID = "$1" ]; then
echo " SID Aprobado "
##### cargando el profile administrador
. $HOME/bin/.profile_admin
indice="`indiceDeGrupoDeInstancia $check_SID `"
RECTAPE="${ATSMOPTDIR[$indice]}"

##### cuatro opciones para los backups
case "$2" in
#opcion para los puntos de partida cero de las copias de seguridad con backup a DISCO
"database_base_to_disk")
opcion="backup database plus archivelog"
;;
#opcion para los puntos de partida cero de las copias de seguridad con backup a CINTA
"database_base_to_tape")
opcion="backup database plus archivelog"
;;
#opcion para un backup completo de la base de datos con backup a DISCO
"full_database_to_disk")
opcion="backup incremental level 0 database"
;;
#opcion para un backup completo de la base de datos con backup a CINTA
"full_database_to_tape")
opcion="backup incremental level 0 database"
;;
#opcion para los incrementos de la base de datos con backup a DISCO
"incremental_database_to_disk")
opcion="backup incremental level 1 database"
;;
#opcion para los incrementos de la base de datos con backup a CINTA
"incremental_database_to_tape")
opcion="backup incremental level 1 database"
;;
#opcion para un backup completo de un solo tablespace con backup a DISCO
"full_tablespace_to_disk")
opcionT="backup incremental level 0 tablespace"
;;
#opcion para un backup completo de un solo tablespace con backup a CINTA
"full_tablespace_to_tape")
opcionT="backup incremental level 0 tablespace"
;;
#opcion para un backup del incremento de un solo tablespace con backup a DISCO
"incremental_tablespace_to_disk")
opcionT="backup incremental level 1 tablespace"
;;
#opcion para un backup del incremento de un solo tablespace con backup a CINTA
"incremental_tablespace_to_tape")
opcionT="backup incremental level 1 tablespace"
;;
esac

if [ "$3" != "" ]; then
disk="${3}"
fi
if [ "$4" != "" ]; then
nametbs="${4}"
fi

####################################################################################################
# [NUEVO - COMENTADO] CONFIGURACIÓN GLOBAL RECOMENDADA EN RMAN (23ai)
# Puedes preconfigurar en RMAN (fuera del script) o insertar como comandos RMAN:
#   CONFIGURE DEVICE TYPE DISK PARALLELISM 4;            -- Paralelismo por defecto (ajusta a tu IO/CPU)
#   CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';            -- MEDIUM (equilibrio CPU/espacio) o 'HIGH'
#   CONFIGURE BACKUP OPTIMIZATION ON;                    -- Evita re-backupear ficheros sin cambios
#   CONFIGURE CONTROLFILE AUTOBACKUP ON;                 -- Autobackup del controlfile y spfile
#   CONFIGURE ENCRYPTION FOR DATABASE ON;                -- (opcional) Cifrar backups
#   CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON ALL STANDBY;  -- Si tienes Data Guard
####################################################################################################

echo " Empezando el proceso de copia "
(
date
case "$2" in

"database_base_to_disk")
echo " Punto de partida para las copias de RMAN "
rman target catalog <<EOF
run
{
  allocate channel disk1 device type disk format '${disk}/full%d%T%s' ;
  resync catalog;
  ${opcion};
  crosscheck archivelog all;
  backup archivelog all;
  release channel disk1;

  -- [NUEVO - COMENTADO] MULTITENANT:
  -- sql "alter session set container=PDB1";

  -- [NUEVO - COMENTADO] COMPRESIÓN Y PARALELISMO (ejemplo sin alterar tu flujo):
  -- CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';
  -- allocate channel disk2 device type disk format '${disk}/full%d%T%s' ;
  -- allocate channel disk3 device type disk format '${disk}/full%d%T%s' ;
  -- backup as compressed backupset database plus archivelog
  --   section size 4G                       -- multisección (acelera en ficheros grandes)
  --   filesperset 1;                         -- sets más pequeños para restauras rápidas
  -- release channel disk2;
  -- release channel disk3;
}
EOF
;;

"database_base_to_tape")
if [ "$3" = "" ]; then
echo " Punto de partida para las copias de RMAN "
echo " Ruta para opcion de backup a cinta $RECTAPE "
rman target catalog <<EOF
run
{
  allocate channel tape1 device type sbt parms='ENV= (TDPO_OPTFILE=${RECTAPE}/tdpo_${1}.opt)';
  format 'full%d%T%s' ;
  ${opcion};
  resync catalog;
  crosscheck archivelog all;
  backup archivelog all;
  release channel tape1;

  -- [NUEVO - COMENTADO] MML alternativos (ejemplos):
  -- allocate channel t1 device type sbt
  --   parms='SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64, ENV=(NB_ORA_POLICY=ORA_POLICY,NB_ORA_SERV=nb-master)';
  -- allocate channel t2 device type sbt
  --   parms='SBT_LIBRARY=/opt/commvault/Base/libobk.so, ENV=(CvClientName=ora-host,CvPolicy=ORA_FULL)';
  -- backup as compressed backupset database plus archivelog;
  -- release channel t1;
  -- release channel t2;
}
EOF
fi
;;

"full_database_to_disk")
echo "Copia de nivel 0 database RMAN "
rman target catalog <<EOF
run
{
  allocate channel disk1 device type disk format '${disk}/full%d%T%s' ;
  ${opcion} ;
  resync catalog;
  crosscheck archivelog all;
  backup archivelog all;
  release channel disk1;

  -- [NUEVO - COMENTADO] Versión moderna del mismo bloque:
  -- allocate channel disk1 device type disk format '${disk}/bkp_level0_%d_%T_%s';
  -- allocate channel disk2 device type disk format '${disk}/bkp_level0_%d_%T_%s';
  -- CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';
  -- backup as compressed backupset incremental level 0 database
  --   section size 8G
  --   filesperset 1
  --   tag 'FULL_L0_COMP';
  -- backup as compressed backupset archivelog all not backed up 1 times delete input
  --   tag 'ARCH_COMP';
  -- release channel disk2;
}
EOF
;;

"full_database_to_tape")
if [ "$3" = "" ]; then
echo "Copia de nivel 0 database RMAN "
echo " Ruta para opcion de backup a cinta $RECTAPE "
rman target catalog <<EOF
run
{
  allocate channel tape1 device type sbt parms='ENV= (TDPO_OPTFILE=${RECTAPE}/tdpo_${1}.opt)';
  format 'bkp_level0%d%T%s' ;
  ${opcion} ;
  resync catalog;
  crosscheck archivelog all;
  backup archivelog all;
  release channel tape1;

  -- [NUEVO - COMENTADO] Paralelismo en cinta + compresión:
  -- allocate channel tape2 device type sbt parms='ENV=(TDPO_OPTFILE=${RECTAPE}/tdpo_${1}.opt)';
  -- CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';
  -- backup as compressed backupset incremental level 0 database tag 'FULL_L0_TAPE';
  -- release channel tape2;
}
EOF
fi
;;

"incremental_database_to_disk")
echo "Copia de nivel 1 database RMAN "
rman target catalog <<EOF
run
{
  allocate channel disk1 device type disk format '${disk}/full%d%T%s' ;
  ${opcion} ;
  resync catalog;
  release channel disk1;

  -- [NUEVO - COMENTADO] L1 optimizado:
  -- allocate channel disk1 device type disk format '${disk}/bkp_level1_%d_%T_%s';
  -- allocate channel disk2 device type disk format '${disk}/bkp_level1_%d_%T_%s';
  -- CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';
  -- backup as compressed backupset incremental level 1 database
  --   section size 8G
  --   tag 'INCR_L1_COMP';
  -- release channel disk2;
}
EOF
;;

"incremental_database_to_tape")
if [ "$3" = "" ]; then
echo "Copia de nivel 1 database RMAN "
echo " Ruta para opcion de backup a cinta $RECTAPE "
rman target catalog <<EOF
run
{
  allocate channel tape1 device type sbt parms='ENV= (TDPO_OPTFILE=${RECTAPE}/tdpo_${1}.opt)';
  format 'bkp_level1%d%T%s' ;
  ${opcion} ;
  resync catalog;
  release channel tape1;

  -- [NUEVO - COMENTADO] Incremental en cinta con compresión:
  -- allocate channel tape2 device type sbt parms='ENV=(TDPO_OPTFILE=${RECTAPE}/tdpo_${1}.opt)';
  -- CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';
  -- backup as compressed backupset incremental level 1 database tag 'INCR_L1_TAPE';
  -- release channel tape2;
}
EOF
fi
;;

"full_tablespace_to_disk")
echo "${opcionT} ${nametbs} RMAN"
rman target catalog <<EOF
run
{
  allocate channel disk1 device type disk format '${disk}/full%d%T%s' ;
  ${opcionT} ${nametbs};
  resync catalog;
  release channel disk1;

  -- [NUEVO - COMENTADO] Tablespace con compresión y multisección:
  -- allocate channel disk2 device type disk format '${disk}/tbs0_%d_%T_%s';
  -- CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';
  -- backup as compressed backupset incremental level 0 tablespace ${nametbs}
  --   section size 4G
  --   filesperset 1
  --   tag 'TBS_L0_COMP';
  -- release channel disk2;
}
EOF
;;

"full_tablespace_to_tape")
if [ "$3" = "" ]; then
nametbs="$3"
echo " ${opcionT} ${nametbs} RMAN "
echo " Ruta para opcion de backup a cinta $RECTAPE "
rman target catalog <<EOF
run
{
  allocate channel tape1 device type sbt parms='ENV= (TDPO_OPTFILE=${RECTAPE}/tdpo_${1}.opt)';
  format 'bkp_tbs0%d%T%s' ;
  ${opcionT} ${nametbs};
  resync catalog;
  release channel tape1;

  -- [NUEVO - COMENTADO] Tablespace a cinta con compresión:
  -- allocate channel tape2 device type sbt parms='ENV=(TDPO_OPTFILE=${RECTAPE}/tdpo_${1}.opt)';
  -- CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';
  -- backup as compressed backupset incremental level 0 tablespace ${nametbs}
  --   tag 'TBS_L0_TAPE';
  -- release channel tape2;
}
EOF
fi
;;

"incremental_tablespace_to_disk")
echo "${opcionT} ${nametbs} RMAN"
rman target catalog <<EOF
run
{
  allocate channel disk1 device type disk format '${disk}/full%d%T%s' ;
  ${opcionT} ${nametbs};
  resync catalog;
  release channel disk1;

  -- [NUEVO - COMENTADO] Incremental de tablespace comprimido:
  -- allocate channel disk2 device type disk format '${disk}/tbs1_%d_%T_%s';
  -- CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';
  -- backup as compressed backupset incremental level 1 tablespace ${nametbs}
  --   section size 4G
  --   tag 'TBS_L1_COMP';
  -- release channel disk2;
}
EOF
;;

"incremental_tablespace_to_tape")
if [ "$3" = "" ]; then
nametbs="$3"
echo "${opcionT} ${nametbs} RMAN"
echo " Ruta para opcion de backup a cinta $RECTAPE "
rman target catalog <<EOF
run
{
  allocate channel tape1 device type sbt parms='ENV= (TDPO_OPTFILE=${RECTAPE}/tdpo_${1}.opt)';
  format 'bkp_tbs1%d%T%s' ;
  ${opcionT} ${nametbs} ;
  resync catalog;
  release channel tape1;

  -- [NUEVO - COMENTADO] Incremental de tablespace en cinta con compresión:
  -- allocate channel tape2 device type sbt parms='ENV=(TDPO_OPTFILE=${RECTAPE}/tdpo_${1}.opt)';
  -- CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';
  -- backup as compressed backupset incremental level 1 tablespace ${nametbs}
  --   tag 'TBS_L1_TAPE';
  -- release channel tape2;
}
EOF
fi
;;
*)
echo " El tipo de backup es un argumento invalido use :
<database_base_to_disk> => El primer backup completo es obligatorio.
<database_base_to_tape> => El primer backup completo es obligatorio.
<full_database_to_disk> => El primer backup + el incremento = es el segundo backup obligatorio para las copias de solo
incremento; es necesario backup_database.
<full_database_to_tape> => El primer backup + el incremento = es el segundo backup obligatorio para las copias de solo
incremento; es necesario backup_database.
<incremental_database_to_disk> => full_database - trabajo = Solo el incremento; es necesario full_database.
<incremental_database_to_tape> => full_database - trabajo = Solo el incremento; es necesario full_database.
<full_tablespace_to_disk> => Copia de un tablespace completo.
<full_tablespace_to_tape> => Copia de un tablespace completo.
<incremental_tablespace_to_disk> Copia el full_tablespace - trabajo sobre el tablespace = Solo el incremento del tablespace.
<incremental_tablespace_to_tape> Copia el full_tablespace - trabajo sobre el tablespace = Solo el incremento del tablespace.
Sintáxis para ejecución: ./backup_RMAN.sh <SID> <tipo_de_backup>
<nombre_tablespace_(Cuando_el_tipo_de_backup_%%_tablespace)> <path_de_almacenamiento_del_backup> . "
;;
esac
date
)
else
echo " El SID especificado es invalido; verifique :
---Que la instancia remota para backup este OPEN.
---Que el SID sea igual al alias del descriptor de conexión.
--- Sintáxis para ejecución: ./backup_RMAN.sh <SID> <tipo_de_backup>
<nombre_tablespace_(Cuando_el_tipo_de_backup_%%_tablespace)> <path_de_almacenamiento_del_backup> . "
fi
else
echo "Base de datos CLOSED"
fi
) >> $LOGFILE 2>&1

####################################################################################################
# [NUEVO - COMENTADO] AVISO/ALERTA AL FINAL (ajustable a tu MTA o monitorización actual)
# mail -s "Backup OK ${1} ${2} ${fecha}" dba@example.com < "$LOGFILE"
# Alternativas modernas:
#   - logger -p local0.info "RMAN Backup ${1} ${2} ${fecha} finalizado"
#   - curl -X POST https://hooks/monitoring ... -d "$(tail -n 200 "$LOGFILE")"
####################################################################################################
mail -s "Backup