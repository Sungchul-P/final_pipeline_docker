set 'commit.interval.ms'='2000';
set 'cache.max.bytes.buffering'='1000000';

CREATE STREAM nc_stream (player varchar, action_name varchar, avg_party_time int) with (kafka_topic='nc_stream', value_format='json');

-- 분당 사용자 행동 횟수
CREATE TABLE action_per_min AS SELECT player, action_name, avg_party_time, WindowStart() AS EVENT_TS, count(*) AS actions FROM nc_stream WINDOW HOPPING (size 60 seconds, advance by 10 seconds) GROUP BY player, action_name, avg_party_time;