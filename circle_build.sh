set -e
set -o pipefail

FLINK_VERSION="1.3.0"
FLINK_DIST_FILE_NAME="flink-${FLINK_VERSION}-bin-hadoop${HADOOP_VERSION_SHORT}-scala_${SCALA_VERSION}.tgz"
HADOOP_VERSION="2.7.2"
HADOOP_VERSION_SHORT=`echo ${HADOOP_VERSION} | cut -f1,2 -d.`
SCALA_VERSION="2.10"

function build_flink() {
    mvn clean install \
    -DskipTests=true \
    -Drat.skip=true \
    -Dhadoop.version=${HADOOP_VERSION}
}

function shade_flink_jar() {
    (cd flink-dist && \
     mvn clean install \
     -DskipTests=true \
     -Drat.skip=true \
     -Dhadoop.version=${HADOOP_VERSION})
}

function build_container() {
    (cd deploy/mesos/frameworks/flink && \
     sudo ./build.sh \
       --from-release \
       --flink-version ${FLINK_VERSION} \
       --hadoop-version ${HADOOP_VERSION_SHORT} \
       --scala-version ${SCALA_VERSION})
}

function upload_s3() {
    (cd flink-dist/target/flink-* && tar -czf /tmp/${FLINK_DIST_FILE_NAME} flink-*)
    aws s3 cp "/tmp/${FLINK_DIST_FILE_NAME}" "s3://branch-builds/apache/flink/${FLINK_VERSION}/${FLINK_DIST_FILE_NAME}"
}

build_flink
shade_flink_jar
upload_s3
build_container




