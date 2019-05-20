set 'commit.interval.ms'='2000';
set 'cache.max.bytes.buffering'='1000000';

-- 지그재그 로그 데이터로 스트림 생성

CREATE STREAM zigzag_stream (ip varchar, user_id int, event_origin varchar, event_name varchar, search_keyword varchar, shop_id varchar) with (kafka_topic='zigzag_stream', value_format='json');

-- 지그재그 유저 데이터로 테이블 생성

CREATE TABLE zigzag_user (userid int, user_name varchar, os varchar, age int, price int, category varchar) with (key='userid', kafka_topic='zigzag_user', value_format='json');

-- 유저정보를 매칭하기 위해서 JOIN 스트림 생성

CREATE STREAM user_stream AS SELECT user_id, event_origin, event_name, u.user_name, u.os, u.age, u.price, u.category FROM zigzag_stream s LEFT JOIN zigzag_user u ON s.user_id = u.userid;


-- 유저세션 모니터링

CREATE TABLE user_sessions AS SELECT user_id, event_origin, WindowStart() AS EVENT_TS, count(*) AS events FROM zigzag_stream window SESSION (60 seconds) GROUP BY user_id, event_origin;


-- 유저에 대한 모든 정보 집계연산 (TABLE-Window 활용)

CREATE TABLE user_info AS SELECT user_name, os, age, category, price, event_origin, event_name, WindowStart() AS EVENT_TS, COUNT(*) AS count FROM user_stream WINDOW TUMBLING (size 30 seconds) GROUP BY user_name, os, age, category, price, event_origin, event_name;


-- 검색 키워드별 집계연산

CREATE TABLE search_list AS SELECT event_origin, search_keyword, shop_id, WindowStart() AS EVENT_TS, COUNT(*) AS count FROM zigzag_stream WINDOW HOPPING (size 60 seconds, advance by 10 seconds) GROUP BY event_origin, search_keyword, shop_id;