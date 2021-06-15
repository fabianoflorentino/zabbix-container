SET @TIME_STAMP := <TIMESTAMP>;

CREATE TABLE IF NOT EXISTS history_uint_new LIKE history_uint;

INSERT INTO history_uint_new SELECT * FROM history_uint WHERE clock > @TIME_STAMP;

ALTER TABLE history_uint RENAME history_uint_old;

ALTER TABLE history_uint_new RENAME history_uint;

TRUNCATE history_uint_old;

DROP TABLE IF EXISTS history_uint_old;

OPTIMIZE TABLE history_uint;