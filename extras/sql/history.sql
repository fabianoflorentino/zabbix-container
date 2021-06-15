SET @TIME_STAMP := <TIMESTAMP>;

CREATE TABLE IF NOT EXISTS history_new LIKE history;

INSERT INTO history_new SELECT * FROM history WHERE clock > @TIME_STAMP;

ALTER TABLE history RENAME history_old;

ALTER TABLE history_new RENAME history;

TRUNCATE history_old;

DROP TABLE IF EXISTS history_old;

OPTIMIZE TABLE history;