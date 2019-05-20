set 'commit.interval.ms'='2000';
set 'cache.max.bytes.buffering'='1000000';

--1. 크몽 로그 데이터로 스트림 생성

CREATE STREAM kmong_stream (row_uuid varchar, user_id varchar, event_category varchar, app_package_name varchar, app_version varchar, device_manufacturer varchar, os_version varchar, channel varchar, in_app_event_category varchar, in_app_event_label varchar, view_id varchar, view_action varchar) with (kafka_topic='kmong_stream',value_format='json');


-- 페이지별 전환율 및 이탈율 조회
-- 전환율 = view_action 컬럼에서 다음과 같이 계산 (click / view) * 100
CREATE TABLE pages_per_min AS SELECT view_id, event_category, view_action, WindowStart() AS EVENT_TS, count(*) AS pages FROM kmong_stream WINDOW HOPPING (size 60 seconds, advance by 10 second) GROUP BY view_id, event_category, view_action;


-- 사용자 기기 제조사별 페이지뷰 및 이탈율 조회(device_manufacturer, view_action)
-- 운영체제 정보도 추가로 조회한다.
CREATE TABLE device_count_per_min AS SELECT device_manufacturer, os_version, event_category, view_action, WindowStart() AS EVENT_TS, count(*) AS pages FROM kmong_stream WINDOW HOPPING (size 60 seconds, advance by 10 second) GROUP BY device_manufacturer, os_version, event_category, view_action;


-- 사용자별 이용 페이지 분석
CREATE TABLE user_count_per_min AS SELECT user_id, event_category, view_id, WindowStart() AS EVENT_TS, count(*) AS pages FROM kmong_stream WINDOW TUMBLING (size 60 seconds) GROUP BY user_id, event_category, view_id;


--2. 크몽 퍼널/카테고리 데이터로 테이블 생성
-- static table(조인에 사용할 테이블)

--CREATE TABLE kmong_funnel (view_id varchar, viewid_desc varchar) with (key='view_id', kafka_topic='kmong_funnel', value_format='json');

-- kmong_stream 과 kmong_funnel 조인하여 스트림 생성
-- view_id 별 설명 컬럼 추가
--CREATE STREAM kmong_view_ids AS SELECT kf.view_id, viewid_desc FROM kmong_stream ks LEFT JOIN kmong_funnel kf ON ks.view_id = kf.view_id;


-- 페이지 뷰의 합계 연산
--CREATE TABLE kmong_view_id_count AS SELECT kf_view_id, viewid_desc, WindowStart() AS EVENT_TS, COUNT(*) AS count FROM kmong_view_ids WINDOW TUMBLING (size 30 seconds) GROUP BY kf_view_id, viewid_desc HAVING COUNT(*) > 1;


--CREATE TABLE kmong_category (category_id varchar, category_name varchar) with (key='category_id', kafka_topic='kmong_category', value_format='json');


-- kmong_stream 과 kmong_category 조인하여 스트림 생성
--CREATE STREAM kmong_categories AS SELECT category_id, category_name FROM kmong_stream ks LEFT JOIN kmong_category kc ON ks.in_app_event_label = kc.category_id;


-- 카테고리별 합계 연산
--CREATE TABLE kmong_category_count AS SELECT category_id, category_name, WindowStart() AS EVENT_TS, COUNT(*) AS count FROM kmong_categories WINDOW TUMBLING (size 30 seconds) GROUP BY category_id, category_name HAVING COUNT(*) > 1;



