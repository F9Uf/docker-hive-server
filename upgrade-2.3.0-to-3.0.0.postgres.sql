SELECT 'Upgrading MetaStore schema from 2.3.0 to 3.0.0';

--\i 040-HIVE-16556.postgres.sql;
CREATE TABLE "METASTORE_DB_PROPERTIES"
(
  "PROPERTY_KEY" VARCHAR(255) NOT NULL,
  "PROPERTY_VALUE" VARCHAR(1000) NOT NULL,
  "DESCRIPTION" VARCHAR(1000)
);

ALTER TABLE ONLY "METASTORE_DB_PROPERTIES"
  ADD CONSTRAINT "PROPERTY_KEY_PK" PRIMARY KEY ("PROPERTY_KEY");

--\i 041-HIVE-16575.postgres.sql;
CREATE INDEX "CONSTRAINTS_CONSTRAINT_TYPE_INDEX" ON "KEY_CONSTRAINTS" USING BTREE ("CONSTRAINT_TYPE");

--\i 042-HIVE-16922.postgres.sql;
UPDATE "SERDE_PARAMS"
SET "PARAM_KEY"='collection.delim'
WHERE "PARAM_KEY"='colelction.delim';

--\i 043-HIVE-16997.postgres.sql;
ALTER TABLE "PART_COL_STATS" ADD COLUMN "BIT_VECTOR" BYTEA;
ALTER TABLE "TAB_COL_STATS" ADD COLUMN "BIT_VECTOR" BYTEA;

--\i 044-HIVE-16886.postgres.sql;
INSERT INTO "NOTIFICATION_SEQUENCE" ("NNI_ID", "NEXT_EVENT_ID") SELECT 1,1 WHERE NOT EXISTS ( SELECT "NEXT_EVENT_ID" FROM "NOTIFICATION_SEQUENCE");

--\i 045-HIVE-17566.postgres.sql;
CREATE TABLE "WM_RESOURCEPLAN" (
    "RP_ID" bigint NOT NULL,
    "NAME" character varying(128) NOT NULL,
    "QUERY_PARALLELISM" integer,
    "STATUS" character varying(20) NOT NULL,
    "DEFAULT_POOL_ID" bigint
);

ALTER TABLE ONLY "WM_RESOURCEPLAN"
    ADD CONSTRAINT "WM_RESOURCEPLAN_pkey" PRIMARY KEY ("RP_ID");

ALTER TABLE ONLY "WM_RESOURCEPLAN"
    ADD CONSTRAINT "UNIQUE_WM_RESOURCEPLAN" UNIQUE ("NAME");


CREATE TABLE "WM_POOL" (
    "POOL_ID" bigint NOT NULL,
    "RP_ID" bigint NOT NULL,
    "PATH" character varying(1024) NOT NULL,
    "ALLOC_FRACTION" double precision,
    "QUERY_PARALLELISM" integer,
    "SCHEDULING_POLICY" character varying(1024)
);

ALTER TABLE ONLY "WM_POOL"
    ADD CONSTRAINT "WM_POOL_pkey" PRIMARY KEY ("POOL_ID");

ALTER TABLE ONLY "WM_POOL"
    ADD CONSTRAINT "UNIQUE_WM_POOL" UNIQUE ("RP_ID", "PATH");

ALTER TABLE ONLY "WM_POOL"
    ADD CONSTRAINT "WM_POOL_FK1" FOREIGN KEY ("RP_ID") REFERENCES "WM_RESOURCEPLAN" ("RP_ID") DEFERRABLE;
ALTER TABLE ONLY "WM_RESOURCEPLAN"
    ADD CONSTRAINT "WM_RESOURCEPLAN_FK1" FOREIGN KEY ("DEFAULT_POOL_ID") REFERENCES "WM_POOL" ("POOL_ID") DEFERRABLE;


CREATE TABLE "WM_TRIGGER" (
    "TRIGGER_ID" bigint NOT NULL,
    "RP_ID" bigint NOT NULL,
    "NAME" character varying(128) NOT NULL,
    "TRIGGER_EXPRESSION" character varying(1024) DEFAULT NULL::character varying,
    "ACTION_EXPRESSION" character varying(1024) DEFAULT NULL::character varying,
    "IS_IN_UNMANAGED" smallint NOT NULL DEFAULT 0
);

ALTER TABLE ONLY "WM_TRIGGER"
    ADD CONSTRAINT "WM_TRIGGER_pkey" PRIMARY KEY ("TRIGGER_ID");

ALTER TABLE ONLY "WM_TRIGGER"
    ADD CONSTRAINT "UNIQUE_WM_TRIGGER" UNIQUE ("RP_ID", "NAME");

ALTER TABLE ONLY "WM_TRIGGER"
    ADD CONSTRAINT "WM_TRIGGER_FK1" FOREIGN KEY ("RP_ID") REFERENCES "WM_RESOURCEPLAN" ("RP_ID") DEFERRABLE;


CREATE TABLE "WM_POOL_TO_TRIGGER" (
    "POOL_ID" bigint NOT NULL,
    "TRIGGER_ID" bigint NOT NULL
);

ALTER TABLE ONLY "WM_POOL_TO_TRIGGER"
    ADD CONSTRAINT "WM_POOL_TO_TRIGGER_pkey" PRIMARY KEY ("POOL_ID", "TRIGGER_ID");

ALTER TABLE ONLY "WM_POOL_TO_TRIGGER"
    ADD CONSTRAINT "WM_POOL_TO_TRIGGER_FK1" FOREIGN KEY ("POOL_ID") REFERENCES "WM_POOL" ("POOL_ID") DEFERRABLE;

ALTER TABLE ONLY "WM_POOL_TO_TRIGGER"
    ADD CONSTRAINT "WM_POOL_TO_TRIGGER_FK2" FOREIGN KEY ("TRIGGER_ID") REFERENCES "WM_TRIGGER" ("TRIGGER_ID") DEFERRABLE;


CREATE TABLE "WM_MAPPING" (
    "MAPPING_ID" bigint NOT NULL,
    "RP_ID" bigint NOT NULL,
    "ENTITY_TYPE" character varying(128) NOT NULL,
    "ENTITY_NAME" character varying(128) NOT NULL,
    "POOL_ID" bigint,
    "ORDERING" integer
);

ALTER TABLE ONLY "WM_MAPPING"
    ADD CONSTRAINT "WM_MAPPING_pkey" PRIMARY KEY ("MAPPING_ID");

ALTER TABLE ONLY "WM_MAPPING"
    ADD CONSTRAINT "UNIQUE_WM_MAPPING" UNIQUE ("RP_ID", "ENTITY_TYPE", "ENTITY_NAME");

ALTER TABLE ONLY "WM_MAPPING"
    ADD CONSTRAINT "WM_MAPPING_FK1" FOREIGN KEY ("RP_ID") REFERENCES "WM_RESOURCEPLAN" ("RP_ID") DEFERRABLE;

ALTER TABLE ONLY "WM_MAPPING"
    ADD CONSTRAINT "WM_MAPPING_FK2" FOREIGN KEY ("POOL_ID") REFERENCES "WM_POOL" ("POOL_ID") DEFERRABLE;

-- Upgrades for Schema Registry objects
ALTER TABLE "SERDES" ADD COLUMN "DESCRIPTION" VARCHAR(4000);
ALTER TABLE "SERDES" ADD COLUMN "SERIALIZER_CLASS" VARCHAR(4000);
ALTER TABLE "SERDES" ADD COLUMN "DESERIALIZER_CLASS" VARCHAR(4000);
ALTER TABLE "SERDES" ADD COLUMN "SERDE_TYPE" INTEGER;

CREATE TABLE "I_SCHEMA" (
  "SCHEMA_ID" bigint primary key,
  "SCHEMA_TYPE" integer not null,
  "NAME" varchar(256) unique,
  "DB_ID" bigint references "DBS" ("DB_ID"),
  "COMPATIBILITY" integer not null,
  "VALIDATION_LEVEL" integer not null,
  "CAN_EVOLVE" boolean not null,
  "SCHEMA_GROUP" varchar(256),
  "DESCRIPTION" varchar(4000)
);

CREATE TABLE "SCHEMA_VERSION" (
  "SCHEMA_VERSION_ID" bigint primary key,
  "SCHEMA_ID" bigint references "I_SCHEMA" ("SCHEMA_ID"),
  "VERSION" integer not null,
  "CREATED_AT" bigint not null,
  "CD_ID" bigint references "CDS" ("CD_ID"), 
  "STATE" integer not null,
  "DESCRIPTION" varchar(4000),
  "SCHEMA_TEXT" text,
  "FINGERPRINT" varchar(256),
  "SCHEMA_VERSION_NAME" varchar(256),
  "SERDE_ID" bigint references "SERDES" ("SERDE_ID"), 
  unique ("SCHEMA_ID", "VERSION")
);


-- 047-HIVE-14498
CREATE TABLE "MV_CREATION_METADATA" (
    "MV_CREATION_METADATA_ID" bigint NOT NULL,
    "CAT_NAME" character varying(256) NOT NULL,
    "DB_NAME" character varying(128) NOT NULL,
    "TBL_NAME" character varying(256) NOT NULL,
    "TXN_LIST" text
);

CREATE TABLE "MV_TABLES_USED" (
    "MV_CREATION_METADATA_ID" bigint NOT NULL,
    "TBL_ID" bigint NOT NULL
);

ALTER TABLE ONLY "MV_CREATION_METADATA"
    ADD CONSTRAINT "MV_CREATION_METADATA_PK" PRIMARY KEY ("MV_CREATION_METADATA_ID");

CREATE INDEX "MV_UNIQUE_TABLE"
    ON "MV_CREATION_METADATA" USING btree ("TBL_NAME", "DB_NAME");

ALTER TABLE ONLY "MV_TABLES_USED"
    ADD CONSTRAINT "MV_TABLES_USED_FK1" FOREIGN KEY ("MV_CREATION_METADATA_ID") REFERENCES "MV_CREATION_METADATA" ("MV_CREATION_METADATA_ID") DEFERRABLE;

ALTER TABLE ONLY "MV_TABLES_USED"
    ADD CONSTRAINT "MV_TABLES_USED_FK2" FOREIGN KEY ("TBL_ID") REFERENCES "TBLS" ("TBL_ID") DEFERRABLE;

ALTER TABLE COMPLETED_TXN_COMPONENTS ADD COLUMN CTC_TIMESTAMP timestamp NULL;

ALTER TABLE "TBLS" ADD COLUMN "OWNER_TYPE" character varying(10) DEFAULT NULL::character varying;

UPDATE COMPLETED_TXN_COMPONENTS SET CTC_TIMESTAMP = CURRENT_TIMESTAMP;

ALTER TABLE COMPLETED_TXN_COMPONENTS ALTER COLUMN CTC_TIMESTAMP SET NOT NULL;

ALTER TABLE COMPLETED_TXN_COMPONENTS ALTER COLUMN CTC_TIMESTAMP SET DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX COMPLETED_TXN_COMPONENTS_INDEX ON COMPLETED_TXN_COMPONENTS USING btree (CTC_DATABASE, CTC_TABLE, CTC_PARTITION);

-- 048-HIVE-18489
UPDATE "FUNC_RU"
  SET "RESOURCE_URI" = 's3a' || SUBSTR("RESOURCE_URI", 4)
  WHERE "RESOURCE_URI" LIKE 's3n://%' ;

UPDATE "SKEWED_COL_VALUE_LOC_MAP"
  SET "LOCATION" = 's3a' || SUBSTR("LOCATION", 4)
  WHERE "LOCATION" LIKE 's3n://%' ;

UPDATE "SDS"
  SET "LOCATION" = 's3a' || SUBSTR("LOCATION", 4)
  WHERE "LOCATION" LIKE 's3n://%' ;

UPDATE "DBS"
  SET "DB_LOCATION_URI" = 's3a' || SUBSTR("DB_LOCATION_URI", 4)
  WHERE "DB_LOCATION_URI" LIKE 's3n://%' ;

-- HIVE-18192
CREATE TABLE TXN_TO_WRITE_ID (
  T2W_TXNID bigint NOT NULL,
  T2W_DATABASE varchar(128) NOT NULL,
  T2W_TABLE varchar(256) NOT NULL,
  T2W_WRITEID bigint NOT NULL
);

CREATE UNIQUE INDEX TBL_TO_TXN_ID_IDX ON TXN_TO_WRITE_ID (T2W_DATABASE, T2W_TABLE, T2W_TXNID);
CREATE UNIQUE INDEX TBL_TO_WRITE_ID_IDX ON TXN_TO_WRITE_ID (T2W_DATABASE, T2W_TABLE, T2W_WRITEID);

CREATE TABLE NEXT_WRITE_ID (
  NWI_DATABASE varchar(128) NOT NULL,
  NWI_TABLE varchar(256) NOT NULL,
  NWI_NEXT bigint NOT NULL
);

CREATE UNIQUE INDEX NEXT_WRITE_ID_IDX ON NEXT_WRITE_ID (NWI_DATABASE, NWI_TABLE);

ALTER TABLE COMPACTION_QUEUE RENAME CQ_HIGHEST_TXN_ID TO CQ_HIGHEST_WRITE_ID;

ALTER TABLE COMPLETED_COMPACTIONS RENAME CC_HIGHEST_TXN_ID TO CC_HIGHEST_WRITE_ID;

-- Modify txn_components/completed_txn_components tables to add write id.
ALTER TABLE TXN_COMPONENTS ADD TC_WRITEID bigint;
ALTER TABLE COMPLETED_TXN_COMPONENTS ADD CTC_WRITEID bigint;

-- HIVE-18726
-- add a new column to support default value for DEFAULT constraint
ALTER TABLE "KEY_CONSTRAINTS" ADD COLUMN "DEFAULT_VALUE" VARCHAR(400);
ALTER TABLE "KEY_CONSTRAINTS" ALTER COLUMN "PARENT_CD_ID" DROP NOT NULL;

ALTER TABLE COMPLETED_TXN_COMPONENTS ALTER COLUMN CTC_TIMESTAMP SET NOT NULL;

ALTER TABLE HIVE_LOCKS ALTER COLUMN HL_TXNID SET NOT NULL;

-- HIVE-18755, add catalogs
-- new catalogs table
CREATE TABLE "CTLGS" (
    "CTLG_ID" BIGINT PRIMARY KEY,
    "NAME" VARCHAR(256) UNIQUE,
    "DESC" VARCHAR(4000),
    "LOCATION_URI" VARCHAR(4000) NOT NULL
);

-- Insert a default value.  The location is TBD.  Hive will fix this when it starts
INSERT INTO "CTLGS" VALUES (1, 'hive', 'Default catalog for Hive', 'TBD');

-- Drop the unique index on DBS
ALTER TABLE "DBS" DROP CONSTRAINT "UNIQUE_DATABASE";

-- Add the new column to the DBS table, can't put in the not null constraint yet
ALTER TABLE "DBS" ADD "CTLG_NAME" VARCHAR(256);

-- Update all records in the DBS table to point to the Hive catalog
UPDATE "DBS" 
  SET "CTLG_NAME" = 'hive';

-- Add the not null constraint
ALTER TABLE "DBS" ALTER COLUMN "CTLG_NAME" SET NOT NULL;

-- Add the default catalog name
ALTER TABLE "DBS" ALTER COLUMN "CTLG_NAME" SET DEFAULT 'hive';

-- Put back the unique index
ALTER TABLE "DBS" ADD CONSTRAINT "UNIQUE_DATABASE" UNIQUE ("NAME", "CTLG_NAME");

-- Add the foreign key
ALTER TABLE "DBS" ADD CONSTRAINT "DBS_FK1" FOREIGN KEY ("CTLG_NAME") REFERENCES "CTLGS" ("NAME");

-- Add columns to table stats and part stats
ALTER TABLE "TAB_COL_STATS" ADD "CAT_NAME" varchar(256);
ALTER TABLE "PART_COL_STATS" ADD "CAT_NAME" varchar(256);

-- Set the existing column names to Hive
UPDATE "TAB_COL_STATS"
  SET "CAT_NAME" = 'hive';
UPDATE "PART_COL_STATS"
  SET "CAT_NAME" = 'hive';

-- Add the not null constraint
ALTER TABLE "TAB_COL_STATS" ALTER COLUMN "CAT_NAME" SET NOT NULL;
ALTER TABLE "PART_COL_STATS" ALTER COLUMN "CAT_NAME" SET NOT NULL;

-- Rebuild the index for Part col stats.  No such index for table stats, which seems weird
DROP INDEX "PCS_STATS_IDX";
CREATE INDEX "PCS_STATS_IDX" ON "PART_COL_STATS" ("CAT_NAME", "DB_NAME", "TABLE_NAME", "COLUMN_NAME", "PARTITION_NAME");

-- Add column to partition event
ALTER TABLE "PARTITION_EVENTS" ADD "CAT_NAME" varchar(256);
UPDATE "PARTITION_EVENTS"
  SET "CAT_NAME" = 'hive' WHERE "DB_NAME" IS NOT NULL;

-- Add column to notification log
ALTER TABLE "NOTIFICATION_LOG" ADD "CAT_NAME" varchar(256);
UPDATE "NOTIFICATION_LOG"
  SET "CAT_NAME" = 'hive' WHERE "DB_NAME" IS NOT NULL;

CREATE TABLE REPL_TXN_MAP (
  RTM_REPL_POLICY varchar(256) NOT NULL,
  RTM_SRC_TXN_ID bigint NOT NULL,
  RTM_TARGET_TXN_ID bigint NOT NULL,
  PRIMARY KEY (RTM_REPL_POLICY, RTM_SRC_TXN_ID)
);

INSERT INTO "SEQUENCE_TABLE" ("SEQUENCE_NAME", "NEXT_VAL") SELECT 'org.apache.hadoop.hive.metastore.model.MNotificationLog',1 WHERE NOT EXISTS ( SELECT "NEXT_VAL" FROM "SEQUENCE_TABLE" WHERE "SEQUENCE_NAME" = 'org.apache.hadoop.hive.metastore.model.MNotificationLog');

-- HIVE_18747
CREATE TABLE MIN_HISTORY_LEVEL (
  MHL_TXNID bigint NOT NULL,
  MHL_MIN_OPEN_TXNID bigint NOT NULL,
  PRIMARY KEY(MHL_TXNID)
);

CREATE INDEX MIN_HISTORY_LEVEL_IDX ON MIN_HISTORY_LEVEL (MHL_MIN_OPEN_TXNID);

CREATE TABLE RUNTIME_STATS (
 RS_ID bigint primary key,
 CREATE_TIME bigint NOT NULL,
 WEIGHT bigint NOT NULL,
 PAYLOAD bytea
);

CREATE INDEX IDX_RUNTIME_STATS_CREATE_TIME ON RUNTIME_STATS(CREATE_TIME);

-- HIVE-18193
-- Populate NEXT_WRITE_ID for each Transactional table and set next write ID same as next txn ID
INSERT INTO NEXT_WRITE_ID (NWI_DATABASE, NWI_TABLE, NWI_NEXT)
    SELECT * FROM
        (SELECT "DB"."NAME", "TBL_INFO"."TBL_NAME" FROM "DBS" "DB",
            (SELECT "TBL"."DB_ID", "TBL"."TBL_NAME" FROM "TBLS" "TBL",
                (SELECT "TBL_ID" FROM "TABLE_PARAMS" WHERE "PARAM_KEY"='transactional' AND "PARAM_VALUE"='true') "TBL_PARAM"
            WHERE "TBL"."TBL_ID"="TBL_PARAM"."TBL_ID") "TBL_INFO"
        where "DB"."DB_ID"="TBL_INFO"."DB_ID") "DB_TBL_NAME",
        (SELECT NTXN_NEXT FROM NEXT_TXN_ID) "NEXT_WRITE";

-- Populate TXN_TO_WRITE_ID for each aborted/open txns and set write ID equal to txn ID
INSERT INTO TXN_TO_WRITE_ID (T2W_DATABASE, T2W_TABLE, T2W_TXNID, T2W_WRITEID)
    SELECT * FROM
        (SELECT "DB"."NAME", "TBL_INFO"."TBL_NAME" FROM "DBS" "DB",
            (SELECT "TBL"."DB_ID", "TBL"."TBL_NAME" FROM "TBLS" "TBL",
                (SELECT "TBL_ID" FROM "TABLE_PARAMS" WHERE "PARAM_KEY"='transactional' AND "PARAM_VALUE"='true') "TBL_PARAM"
            WHERE "TBL"."TBL_ID"="TBL_PARAM"."TBL_ID") "TBL_INFO"
        where "DB"."DB_ID"="TBL_INFO"."DB_ID") "DB_TBL_NAME",
        (SELECT TXN_ID, TXN_ID as WRITE_ID FROM TXNS) "TXN_INFO";

-- Update TXN_COMPONENTS and COMPLETED_TXN_COMPONENTS for write ID which is same as txn ID
UPDATE TXN_COMPONENTS SET TC_WRITEID = TC_TXNID;
UPDATE COMPLETED_TXN_COMPONENTS SET CTC_WRITEID = CTC_TXNID;

-- These lines need to be last.  Insert any changes above.
UPDATE "VERSION" SET "SCHEMA_VERSION"='3.0.0', "VERSION_COMMENT"='Hive release version 3.0.0' where "VER_ID"=1;
SELECT 'Finished upgrading MetaStore schema from 2.3.0 to 3.0.0';