#!/usr/bin/env bash
set -e
LAMBDA_FILE="lambda.zip"

rm -f ${LAMBDA_FILE}

mkdir -p clamav

echo "-- Downloading AmazonLinux container --"
docker pull amazonlinux
docker create -i -t -v ${PWD}/clamav:/home/docker  --name s3-antivirus-builder amazonlinux
docker start s3-antivirus-builder

echo "-- Updating, downloading and unpacking clamAV and ClamAV update --"
docker exec -it -w /home/docker s3-antivirus-builder yum install -y cpio yum-utils
docker exec -it -w /home/docker s3-antivirus-builder yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
docker exec -it -w /home/docker s3-antivirus-builder yum-config-manager --enable epel
docker exec -it -w /home/docker s3-antivirus-builder yumdownloader -x \*i686 --archlist=x86_64 clamav clamav-lib clamav-update json-c pcre2 libxml2 bzip2-libs libtool-ltdl xz-libs libprelude gnutls libcurl curl nettle libnghttp2 libidn2 libssh2 openldap libunistring cyrus-sasl-lib nss libgcrypt
docker exec -it -w /home/docker s3-antivirus-builder /bin/sh -c "echo 'folder content' && ls -la"
docker exec -it -w /home/docker s3-antivirus-builder /bin/sh -c "rpm2cpio clamav-0*.rpm | cpio -idmv"
docker exec -it -w /home/docker s3-antivirus-builder /bin/sh -c "rpm2cpio clamav-lib*.rpm | cpio -idmv"
docker exec -it -w /home/docker s3-antivirus-builder /bin/sh -c "rpm2cpio clamav-update*.rpm | cpio -idmv"
docker exec -it -w /home/docker s3-antivirus-builder /bin/sh -c "rpm2cpio json-c*.rpm | cpio -idmv"
docker exec -it -w /home/docker s3-antivirus-builder /bin/sh -c "rpm2cpio pcre2*.rpm | cpio -idmv"
docker exec -it -w /home/docker s3-antivirus-builder /bin/sh -c "rpm2cpio libxml2*.rpm | cpio -idmv"
docker exec -it -w /home/docker s3-antivirus-builder /bin/sh -c "rpm2cpio bzip2-libs*.rpm | cpio -idmv"
docker exec -it -w /home/docker s3-antivirus-builder /bin/sh -c "rpm2cpio libtool-ltdl*.rpm | cpio -idmv"
docker exec -it -w /home/docker s3-antivirus-builder /bin/sh -c "rpm2cpio xz-libs*.rpm | cpio -idmv"
docker exec -it -w /home/docker s3-antivirus-builder /bin/sh -c "rpm2cpio libprelude*.rpm | cpio -idmv"
docker exec -it -w /home/docker s3-antivirus-builder /bin/sh -c "rpm2cpio gnutls*.rpm | cpio -idmv"
docker exec -it -w /home/docker s3-antivirus-builder /bin/sh -c "rpm2cpio libcurl*.rpm | cpio -idmv"
docker exec -it -w /home/docker s3-antivirus-builder /bin/sh -c "rpm2cpio curl*.rpm | cpio -idmv"
docker exec -it -w /home/docker s3-antivirus-builder /bin/sh -c "rpm2cpio nettle*.rpm | cpio -idmv"
docker exec -it -w /home/docker s3-antivirus-builder /bin/sh -c "rpm2cpio libnghttp2*.rpm | cpio -idmv"
docker exec -it -w /home/docker s3-antivirus-builder /bin/sh -c "rpm2cpio libidn2*.rpm | cpio -idmv"
docker exec -it -w /home/docker s3-antivirus-builder /bin/sh -c "rpm2cpio libssh2*.rpm | cpio -idmv"
docker exec -it -w /home/docker s3-antivirus-builder /bin/sh -c "rpm2cpio openldap*.rpm | cpio -idmv"
docker exec -it -w /home/docker s3-antivirus-builder /bin/sh -c "rpm2cpio libunistring*.rpm | cpio -idmv"
docker exec -it -w /home/docker s3-antivirus-builder /bin/sh -c "rpm2cpio cyrus-sasl-lib*.rpm | cpio -idmv"
docker exec -it -w /home/docker s3-antivirus-builder /bin/sh -c "rpm2cpio nss*.rpm | cpio -idmv"
docker exec -it -w /home/docker s3-antivirus-builder /bin/sh -c "cp /lib64/libcrypt.so.1 usr/lib64/libcrypt.so.1"
docker exec -it -w /home/docker s3-antivirus-builder /bin/sh -c "rpm2cpio libgcrypt*.rpm | cpio -idmv"


docker stop s3-antivirus-builder
docker rm s3-antivirus-builder

mkdir ./bin

echo "-- Copying the executables and required libraries --"
rm -R clamav/usr/lib64/sasl2 clamav/usr/lib64/nss
cp clamav/usr/bin/clamscan clamav/usr/bin/freshclam clamav/usr/lib64/* bin/.

echo "-- Cleaning up ClamAV folder --"
rm -rf clamav

cp -R ./s3-antivirus/* bin/.

pushd ./bin
zip -r9 ${LAMBDA_FILE} *
popd

cp bin/${LAMBDA_FILE} .

echo "-- Cleaning up bin folder --"
rm -rf bin