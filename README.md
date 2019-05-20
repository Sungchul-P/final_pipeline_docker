
# Download
---

- HI 플랫폼 환경구축에 필요한 파일들은 GitHub에서 Clone으로 가져오셔서 준비를 하시면 됩니다.[https://github.com/Sungchul-P/streamdata_pipeline.git](https://github.com/Sungchul-P/streamdata_pipeline.git)

> git clone https://github.com/Sungchul-P/final_pipeline_docker.git


## Step One Container 환경 구축
---

- 다운로드하신 HI 플랫폼의 파일 Tree구조입니다.

```
(디렉터리).
    │  docker-compose.yml
    │  Dockerfile
    │  out.txt
    │  README.md
    │
    ├─conf
    │  │  elasticsearch.yml
    │  │  grafana.ini
    │  │
    │  ├─master
    │  │      spark-defaults.conf
    │  │
    │  └─worker
    │          spark-defaults.conf
    │
    ├─data
    │  ├─kmong
    │  │      kmong-schema.sql
    │  │      kmong_schema.avro
    │  │
    │  ├─nc
    │  │      nc_schema.avro
    │  │      nc_schema.sql
    │  │
    │  └─zigzag
    │          zigzag_schema.avro
    │          zigzag_schema.sql
    │          zigzag_user_schema.avro
    │
    ├─data_sources
    │      aa
    │      ab
    │      ac
    │      ad
    │      ae
    │      af
    │      ag
    │
    ├─grafana_dashboard
    │      Kmong Dashboard-Grafana_v0.2.json
    │      NC Dashboard-Grafana_v0.1.json
    │      ZigZag Dashboard-Grafana_v0.1.json
    │
    └─nifi_template
            Kmong_Stream_v0.2.xml
            NC_Stream_v0.1.xml
            Zigzag_Stream_v0.1.xml
```

- Docker-compose 명령어를 통해 Container를 환경을 구축합니다.

> docker-compose up -d


- 구축 시 필요한 파일은 **`Dockerfile`** 과 **`docker-compose.yml`** 파일입니다.
  - 구성이 완료되면 아래와 같이 명령어를 통해서 확인을 하실 수 있습니다.

> docker-compose ps 

```
datagen           bash -c echo Waiting for K ...   Up
elasticsearch     /usr/local/bin/docker-entr ...   Up      0.0.0.0:9200->9200/tcp, 0.0.0.0:9300->9300/tcp
grafana           /run.sh                          Up      0.0.0.0:23000->3000/tcp
kafka-1           /etc/confluent/docker/run        Up      9092/tcp
kafka-2           /etc/confluent/docker/run        Up      9092/tcp
kafka-3           /etc/confluent/docker/run        Up      9092/tcp
kafka-connect     /etc/confluent/docker/run        Up      0.0.0.0:28083->8083/tcp, 9092/tcp
kibana            /usr/local/bin/kibana-docker     Up      0.0.0.0:5601->5601/tcp
ksql-cli          /bin/sh                          Up
ksql-server       /etc/confluent/docker/run        Up      0.0.0.0:28088->8088/tcp
nifi              ../scripts/start.sh              Up      10000/tcp, 0.0.0.0:8080->8080/tcp, 8443/tcp
schema-registry   /etc/confluent/docker/run        Up      8081/tcp
zookeeper-1       /etc/confluent/docker/run        Up      0.0.0.0:12181->2181/tcp, 2888/tcp, 3888/tcp
zookeeper-2       /etc/confluent/docker/run        Up      0.0.0.0:22181->2181/tcp, 2888/tcp, 3888/tcp
zookeeper-3       /etc/confluent/docker/run        Up      0.0.0.0:32181->2181/tcp, 2888/tcp, 3888/tcp
```

## Step Two 각각의 데이터 셋 Datagenerate
---

- 다운로드한 데이터셋 파일을 **`datagen`** Container로 cp를 하여, Generate를 진행합니다.
  [**`*.avro`**, **`*.sql`**]

> docker cp kmong_schema.avro datagen:/tmp/data/kmong/kmong_schema.avro
> docker cp nc_schema.avro datagen:/tmp/data/nc/nc_schema.avro
> docker cp zigzag_schema.avro datagen:/tmp/data/zigzag/zigzag_schema.avro
> docker cp zigzag_user_schema.avro datagen:/tmp/data/zigzag/zigzag_user_schema.avro
>
> docker cp kmong-schema.sql datagen:/tmp/data/kmong/kmong-schema.sql
> docker cp nc_schema.sql datagen:/tmp/data/nc/nc_schema.sql
> docker cp zigzag_schema.sql datagen:/tmp/data/zigzag/zigzag_schema.sql


- 각각의 터미널에서 명령어를 수행하면, Data가 Generate됩니다.
```
• kmong 데이터셋
    docker-compose exec datagen \
    ksql-datagen \
    bootstrap-server=kafka-1:19092 \
    schema=/tmp/data/kmong/kmong_schema.avro \
    format=json \
    topic=kmong_stream \
    maxInterval=100 \
    key=row_uuid

• zigzag 데이터셋
    docker-compose exec datagen \
    ksql-datagen \
    bootstrap-server=kafka-1:19092 \
    schema=/tmp/data/zigzag/zigzag_schema.avro \
    format=json \
    topic=zigzag_stream \
    maxInterval=100 \
    key=ip

    docker-compose exec datagen \
    ksql-datagen \
    bootstrap-server=kafka-1:19092 \
    schema=/tmp/data/zigzag/zigzag_user_schema.avro \
    format=json \
    topic=zigzag_user \
    maxInterval=100 \
    key=userid

• nc 데이터셋
    docker-compose exec datagen \
    ksql-datagen \
    bootstrap-server=kafka-1:19092 \
    schema=/tmp/data/nc/nc_schema.avro \
    format=json \
    topic=nc_stream \
    maxInterval=100 \
    key=player
```


## Step Three KSQL Schema 생성
---


- 다른 터미널에서 KSQL 실행하여, Stream과 Table을 생성합니다.

> docker-compose exec ksql-cli ksql http://ksql-server:8088


- Script를 통해 손쉽게 Stream,Table을 생성하실 수 있습니다.

> RUN SCRIPT '/tmp/data/kmong/kmong-schema.sql';
> RUN SCRIPT '/tmp/data/zigzag/zigzag_schema.sql';
> RUN SCRIPT '/tmp/data/nc/nc_schema.sql';


## Step Four Nifi
---

- Nifi 접속 주소(http://localhost:8080)를 통해 접속 가능합니다.
- `nifi_template` 디렉터리의 **`Kmong_Stream_v0.2.xml`**, **`NC_Stream_v0.1.xml`**, **`Zigzag_Stream_v0.1.xml`** 파일을 업로드하고 실행을 하면 됩니다.


## Step Five Grafana
---

- Grafana 접속주소(http://localhost:23000)를 통해 접속 가능합니다.
