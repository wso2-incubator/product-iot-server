-- Before running this script, please make sure that DM_OPERATION does have the INITIATED_BY column. Some customers
-- may have it because of a patch. But Some customers may not have it, therefore depending on the situation, please
-- comment or uncomment one of first two ALTER TABLE DM_OPERATION SQL commands.

-- ALTER TABLE DM_OPERATION
-- ADD COLUMN INITIATED_BY VARCHAR(100) NULL DEFAULT NULL AFTER OPERATION_CODE;

ALTER TABLE DM_OPERATION
CHANGE COLUMN INITIATED_BY INITIATED_BY VARCHAR(100) NULL DEFAULT NULL;

ALTER TABLE DM_PROFILE
DROP FOREIGN KEY DM_PROFILE_DEVICE_TYPE;

ALTER TABLE DM_DEVICE_TYPE_POLICY
DROP FOREIGN KEY FK_DEVICE_TYPE_POLICY_DEVICE_TYPE;


ALTER TABLE DM_DEVICE_TYPE
ADD COLUMN DEVICE_TYPE_META VARCHAR(20000) NULL AFTER NAME,
ADD COLUMN LAST_UPDATED_TIMESTAMP TIMESTAMP NULL AFTER DEVICE_TYPE_META;


CREATE INDEX IDX_DEVICE_TYPE_PROVIDER ON DM_DEVICE_TYPE (NAME, PROVIDER_TENANT_ID);
CREATE INDEX IDX_DEVICE_TYPE_DEVICE_NAME ON DM_DEVICE_TYPE(ID, NAME);


CREATE TABLE IF NOT EXISTS DM_GROUP (
  ID          INTEGER AUTO_INCREMENT NOT NULL,
  GROUP_NAME  VARCHAR(100) DEFAULT NULL,
  DESCRIPTION TEXT         DEFAULT NULL,
  OWNER       VARCHAR(45)  DEFAULT NULL,
  TENANT_ID   INTEGER      DEFAULT 0,
  PRIMARY KEY (ID)
)
  ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS DM_ROLE_GROUP_MAP (
  ID        INTEGER AUTO_INCREMENT NOT NULL,
  GROUP_ID  INTEGER     DEFAULT NULL,
  ROLE      VARCHAR(45) DEFAULT NULL,
  TENANT_ID INTEGER     DEFAULT 0,
  PRIMARY KEY (ID),
  CONSTRAINT DM_ROLE_GROUP_MAP_DM_GROUP2 FOREIGN KEY (GROUP_ID)
  REFERENCES DM_GROUP (ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
  ENGINE = InnoDB;


CREATE INDEX IDX_DM_DEVICE_TYPE_ID_DEVICE_IDENTIFICATION ON DM_DEVICE(TENANT_ID, DEVICE_TYPE_ID,DEVICE_IDENTIFICATION);

CREATE TABLE IF NOT EXISTS DM_DEVICE_PROPERTIES (
     DEVICE_TYPE_NAME VARCHAR(300) NOT NULL,
     DEVICE_IDENTIFICATION VARCHAR(300) NOT NULL,
     PROPERTY_NAME VARCHAR(100) DEFAULT 0,
     PROPERTY_VALUE VARCHAR(100) DEFAULT NULL,
     TENANT_ID VARCHAR(100),
     PRIMARY KEY (DEVICE_TYPE_NAME, DEVICE_IDENTIFICATION, PROPERTY_NAME, TENANT_ID)
)ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS DM_DEVICE_GROUP_MAP (
  ID        INTEGER AUTO_INCREMENT NOT NULL,
  DEVICE_ID INTEGER DEFAULT NULL,
  GROUP_ID  INTEGER DEFAULT NULL,
  TENANT_ID INTEGER DEFAULT 0,
  PRIMARY KEY (ID),
  CONSTRAINT fk_DM_DEVICE_GROUP_MAP_DM_DEVICE2 FOREIGN KEY (DEVICE_ID)
  REFERENCES DM_DEVICE (ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE ,
  CONSTRAINT fk_DM_DEVICE_GROUP_MAP_DM_GROUP2 FOREIGN KEY (GROUP_ID)
  REFERENCES DM_GROUP (ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
  ENGINE = InnoDB;




CREATE INDEX IDX_ENROLMENT_DEVICE_ID_TENANT_ID_STATUS ON DM_ENROLMENT(DEVICE_ID, TENANT_ID, STATUS);

ALTER TABLE DM_ENROLMENT_OP_MAPPING
ADD COLUMN PUSH_NOTIFICATION_STATUS VARCHAR(50) NULL AFTER STATUS;

CREATE INDEX IDX_EN_OP_MAPPING_EN_ID_STATUS ON DM_ENROLMENT_OP_MAPPING(ENROLMENT_ID, STATUS);

ALTER TABLE DM_DEVICE_APPLICATION_MAPPING
ADD COLUMN ENROLMENT_ID INT(11) NULL AFTER DEVICE_ID,
ADD COLUMN APP_PROPERTIES BLOB NULL AFTER TENANT_ID,
ADD COLUMN MEMORY_USAGE INT(11) NULL AFTER APP_PROPERTIES,
ADD COLUMN IS_ACTIVE TINYINT NULL AFTER MEMORY_USAGE;

SET SQL_SAFE_UPDATES = 0;

UPDATE DM_DEVICE_APPLICATION_MAPPING dam,
    DM_ENROLMENT de,
    DM_APPLICATION da
SET
    dam.ENROLMENT_ID = de.ID,
    dam.MEMORY_USAGE = da.MEMORY_USAGE,
    dam.APP_PROPERTIES = da.APP_PROPERTIES,
    dam.IS_ACTIVE = da.IS_ACTIVE
WHERE
    dam.APPLICATION_ID = da.ID
	AND dam.DEVICE_ID = de.DEVICE_ID
    AND de.STATUS = 'ACTIVE';

SET SQL_SAFE_UPDATES = 1;


ALTER TABLE DM_DEVICE_APPLICATION_MAPPING
CHANGE COLUMN IS_ACTIVE IS_ACTIVE TINYINT(4) NOT NULL ,
ADD INDEX FK_DM_APP_MAP_DM_ENROL_idx (ENROLMENT_ID ASC);
ALTER TABLE DM_DEVICE_APPLICATION_MAPPING
ADD CONSTRAINT FK_DM_APP_MAP_DM_ENROL
  FOREIGN KEY (ENROLMENT_ID)
  REFERENCES DM_ENROLMENT (ID)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;


ALTER TABLE DM_DEVICE_GROUP_POLICY
DROP FOREIGN KEY FK_DM_DEVICE_GROUP_DM_POLICY,
DROP FOREIGN KEY FK_DM_DEVICE_GROUP_POLICY;
ALTER TABLE DM_DEVICE_GROUP_POLICY
ADD CONSTRAINT FK_DM_DEVICE_GROUP_DM_POLICY
  FOREIGN KEY (POLICY_ID)
  REFERENCES DM_POLICY (ID)
  ON DELETE CASCADE
  ON UPDATE CASCADE,
ADD CONSTRAINT FK_DM_DEVICE_GROUP_POLICY
  FOREIGN KEY (DEVICE_GROUP_ID)
  REFERENCES DM_GROUP (ID)
  ON DELETE CASCADE
  ON UPDATE CASCADE;


ALTER TABLE DM_NOTIFICATION
DROP FOREIGN KEY fk_dm_operation_notification;
ALTER TABLE DM_NOTIFICATION
CHANGE COLUMN OPERATION_ID OPERATION_ID INT(11) NULL ,
ADD COLUMN LAST_UPDATED_TIMESTAMP TIMESTAMP NULL AFTER DESCRIPTION;


ALTER TABLE DM_NOTIFICATION
CHANGE COLUMN LAST_UPDATED_TIMESTAMP LAST_UPDATED_TIMESTAMP TIMESTAMP NOT NULL ;


ALTER TABLE DM_DEVICE_INFO
ADD COLUMN ENROLMENT_ID INT(11) NULL AFTER DEVICE_ID;

SET SQL_SAFE_UPDATES = 0;


UPDATE DM_DEVICE_INFO di,
    DM_ENROLMENT de
SET
    di.ENROLMENT_ID = de.ID
WHERE
    di.DEVICE_ID = de.DEVICE_ID
        AND de.STATUS = 'ACTIVE';

SET SQL_SAFE_UPDATES = 1;

ALTER TABLE DM_DEVICE_INFO
CHANGE COLUMN ENROLMENT_ID ENROLMENT_ID INT(11) NOT NULL,
ADD INDEX DM_DEVICE_LOCATION_DM_ENROLLMENT_idx (ENROLMENT_ID ASC);
ALTER TABLE DM_DEVICE_INFO
ADD CONSTRAINT DM_DEVICE_LOCATION_DM_ENROLLMENT
  FOREIGN KEY (ENROLMENT_ID)
  REFERENCES DM_ENROLMENT (ID)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;


ALTER TABLE DM_DEVICE_LOCATION
CHANGE COLUMN STREET1 STREET1 VARCHAR(255) NULL DEFAULT NULL ,
CHANGE COLUMN STREET2 STREET2 VARCHAR(255) NULL DEFAULT NULL ,
ADD COLUMN ENROLMENT_ID INT(11) NULL AFTER DEVICE_ID,
ADD COLUMN GEO_HASH VARCHAR(45) NULL AFTER UPDATE_TIMESTAMP,
ADD INDEX DM_DEVICE_LOCATION_GEO_hashx (GEO_HASH ASC);


SET SQL_SAFE_UPDATES = 0;


UPDATE DM_DEVICE_LOCATION di,
    DM_ENROLMENT de
SET
    di.ENROLMENT_ID = de.ID
WHERE
    di.DEVICE_ID = de.DEVICE_ID
        AND de.STATUS = 'ACTIVE';

SET SQL_SAFE_UPDATES = 1;

ALTER TABLE DM_DEVICE_LOCATION
CHANGE COLUMN ENROLMENT_ID ENROLMENT_ID INT(11) NOT NULL ,
ADD INDEX DM_DEVICE_LOCATION_DM_ENROLLMENT_idx (ENROLMENT_ID ASC);
ALTER TABLE DM_DEVICE_LOCATION
ADD CONSTRAINT FK_DM_DEVICE_LOCATION_DM_ENROLLMENT
  FOREIGN KEY (ENROLMENT_ID)
  REFERENCES DM_ENROLMENT (ID)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;


ALTER TABLE DM_DEVICE_DETAIL
CHANGE COLUMN CONNECTION_TYPE CONNECTION_TYPE VARCHAR(50) NULL DEFAULT NULL ,
ADD COLUMN ENROLMENT_ID INT(11) NULL AFTER DEVICE_ID;


SET SQL_SAFE_UPDATES = 0;


UPDATE DM_DEVICE_DETAIL di,
    DM_ENROLMENT de
SET
    di.ENROLMENT_ID = de.ID
WHERE
    di.DEVICE_ID = de.DEVICE_ID
        AND de.STATUS = 'ACTIVE';

SET SQL_SAFE_UPDATES = 1;

ALTER TABLE DM_DEVICE_DETAIL
CHANGE COLUMN ENROLMENT_ID ENROLMENT_ID INT(11) NOT NULL ,
ADD INDEX FK_DM_ENROLMENT_DEVICE_DETAILS_idx (ENROLMENT_ID ASC);
ALTER TABLE DM_DEVICE_DETAIL
ADD CONSTRAINT FK_DM_ENROLMENT_DEVICE_DETAILS
  FOREIGN KEY (ENROLMENT_ID)
  REFERENCES DM_ENROLMENT (ID)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;



-- TEMP TABLE REQUIRED FOR DATA ARCHIVAL JOB
CREATE TABLE IF NOT EXISTS DM_ARCHIVED_OPERATIONS (
    ID INTEGER NOT NULL,
    CREATED_TIMESTAMP TIMESTAMP NOT NULL,
    PRIMARY KEY (ID)
)ENGINE = InnoDB;



