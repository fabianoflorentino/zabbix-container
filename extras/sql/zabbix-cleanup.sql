SET @TIME_STAMP := <TIMESTAMP>;

DELETE FROM history_uint WHERE CLOCK < @TIME_STAMP;
OPTIMIZE TABLE history_uint;

DELETE FROM history WHERE CLOCK < @TIME_STAMP;
OPTIMIZE TABLE history;

DELETE FROM trends WHERE CLOCK < @TIME_STAMP;
OPTIMIZE TABLE trends;

DELETE FROM trends_uint WHERE CLOCK < @TIME_STAMP;
OPTIMIZE TABLE trends_uint;