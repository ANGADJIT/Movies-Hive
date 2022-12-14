
-- * Loading And Cleaning Data

-- Create Base Table and load data into that
CREATE TEMPORARY TABLE PROJ.MOVIES_BASE(
    ID STRING,NAME STRING,YEAR STRING,TIMING STRING,RATING DOUBLE,VOTES STRING,GENRE STRING,LANG STRING 
) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' STORED AS TEXTFILE;

LOAD DATA INPATH '/data/movies.csv' OVERWRITE INTO TABLE PROJ.MOVIES_BASE;

-- Enable ACID
SET hive.support.concurrency=true;
SET hive.txn.manager=org.apache.hadoop.hive.ql.lockmgr.DbTxnManager;
SET hive.enforce.bucketing=true;
SET hive.exec.dynamic.partition.mode=nostrict;
SET hive.compactor.initiator.on=true;
SET hive.compactor.worker.threads=1;

-- Create Table TYPE=ACID And LOAD Data From Base Table Excluding ID Column
CREATE TEMPORARY TABLE PROJ.MOVIES_ACID(
    NAME STRING,YEAR STRING,TIMING STRING,RATING DOUBLE,VOTES STRING,GENRE STRING,LANG STRING 
) CLUSTERED BY (NAME) INTO 1 BUCKETS
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' STORED AS ORC TBLPROPERTIES('transactional'='true');

INSERT INTO TABLE PROJ.MOVIES_ACID SELECT NAME,YEAR,TIMING,RATING,VOTES,GENRE,LANG FROM PROJ.MOVIES_BASE;

-- Peform Transformation of Movies ACID Tables
UPDATE PROJ.MOVIES_ACID SET YEAR=REGEXP_EXTRACT(YEAR,'[0-9]+',0);
UPDATE PROJ.MOVIES_ACID SET TIMING=REGEXP_REPLACE(TIMING,' min','');
UPDATE PROJ.MOVIES_ACID SET VOTES=REGEXP_REPLACE(VOTES,',','');

-- Create Main Movies Table And Load Transformed Data From MOVIES_ACID
CREATE TEMPORARY TABLE PROJ.MOVIES(
    NAME STRING,YEAR INT,TIMING INT,RATING DOUBLE,VOTES INT,GENRE STRING,LANG STRING 
) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' STORED AS PARQUET;

INSERT OVERWRITE TABLE PROJ.MOVIES SELECT * FROM PROJ.MOVIES_ACID;

--* Queries And Its Outputs 

-- 1
INSERT OVERWRITE DIRECTORY '/outputs/query1' SELECT * FROM PROJ.MOVIES WHERE SUBSTR(NAME,3,1)='s' AND 
LENGTH(NAME)=6;

-- 2
INSERT OVERWRITE DIRECTORY '/outputs/query2' SELECT NAME,RATING,LANG FROM PROJ.MOVIES WHERE GENRE='-'; 

-- 3
INSERT OVERWRITE DIRECTORY '/outputs/query3' SELECT NAME FROM PROJ.MOVIES WHERE NAME LIKE 'G%';

-- 4
INSERT OVERWRITE DIRECTORY '/outputs/query4' SELECT NAME FROM PROJ.MOVIES WHERE YEAR > 2016;

-- 5
INSERT OVERWRITE DIRECTORY '/outputs/query5' SELECT NAME FROM PROJ.MOVIES WHERE YEAR=2015 AND NAME LIKE 'G%' AND LANG='punjabi';

-- 6
INSERT OVERWRITE DIRECTORY '/outputs/query6' SELECT * FROM PROJ.MOVIES WHERE NAME LIKE '%Bill%' or NAME LIKE '%Man%';

-- 7
INSERT OVERWRITE DIRECTORY '/outputs/query7'  SELECT NAME,VOTES FROM PROJ.MOVIES WHERE GENRE LIKE 'Documentary%' AND VOTES IS NOT NULL;

-- 8
INSERT OVERWRITE DIRECTORY '/outputs/query8'  SELECT NAME,LANG,RATING FROM PROJ.MOVIES WHERE RATING > 8.0 AND RATING IS NOT NULL;

-- 9
INSERT OVERWRITE DIRECTORY '/outputs/query9' SELECT * FROM PROJ.MOVIES WHERE GENRE LIKE 'Comedy%' AND GENRE 
IS NOT NULL;

-- 10
INSERT OVERWRITE DIRECTORY '/outputs/query10' select name,rank() over(order by rating desc) from proj.movies;

-- ** END OF SCRIPT **