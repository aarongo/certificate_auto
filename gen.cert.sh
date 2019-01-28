#!/usr/bin/env bash

if [ -z "$1" ]
then
    echo
    echo '使用 Nexus CA 颁发泛域名证书'
    echo
    echo 'Usage: ./gen.cert.sh <domain> <domain2> <domain3> <domain4> ...'
    echo '    <domain>          输入网站域名, 例如 "example.dev",'
    echo '                      会生成泛域名证书 *.example.dev'
    echo '                      可以输入多个域名进行生成'
    exit;
fi

# 通过变量获取支持的泛证书域名
# 如果多证书可以使用空格隔开输入
SAN=""
for var in "$@"
do
    SAN+="DNS:*.${var},DNS:${var},"
done
SAN=${SAN:0:${#SAN}-1}



# BASH_SOURCE[0] 等价于 BASH_SOURCE， 取得当前执行的shell文件所在的路径
cd "$(dirname "${BASH_SOURCE[0]}")"


# 当根证书不存在时，创建根证书
if [ ! -f "out/root.crt" ]; then
    bash gen.root.sh
fi

# 根据输入的域名进行生成目录创建
BASE_DIR="out/$1"
TIME=`date +%Y%m%d-%H%M`
DIR="${BASE_DIR}/${TIME}"
mkdir -p ${DIR}

# 生成CSR
openssl req -new -out "${DIR}/$1.csr.pem" \
    -key out/cert.key.pem \
    -reqexts SAN \
    -config <(cat ca.cnf \
        <(printf "[SAN]\nsubjectAltName=${SAN}")) \
    -subj "/C=CN/ST=Guangdong/L=Shenzhen/O=Nexus/OU=$1/CN=*.$1"

# 颁发证书
# 使用自签署的 CA 证书签署服务器 CSR 证书请求
openssl ca -config ./ca.cnf -batch -notext \
    -in "${DIR}/$1.csr.pem" \
    -out "${DIR}/$1.crt" \
    -cert ./out/root.crt \
    -keyfile ./out/root.key.pem

# 生成证书链
cat "${DIR}/$1.crt" ./out/root.crt > "${DIR}/$1.bundle.crt"
ln -snf "./${TIME}/$1.bundle.crt" "${BASE_DIR}/$1.bundle.crt"
ln -snf "./${TIME}/$1.crt" "${BASE_DIR}/$1.crt"
ln -snf "../cert.key.pem" "${BASE_DIR}/$1.key.pem"
ln -snf "../root.crt" "${BASE_DIR}/root.crt"

# Output certificates
echo
echo "Certificates are located in:"

LS=$([[ `ls --help | grep '\-\-color'` ]] && echo "ls --color" || echo "ls -G")

${LS} -la `pwd`/${BASE_DIR}/*.*
