#set env vars
set -o allexport; source .env; set +o allexport;

#wait until the server is ready
echo "Waiting for software to be ready ..."
sleep 60s;

if [ -e "./initialized" ]; then
    echo "Already initialized, skipping..."
else
    docker-compose exec -T api bash -c "python3 manage.py migrate"

    docker-compose exec -T api bash -c "python3 manage.py populatedb --createsuperuser --user_password ${ADMIN_PASSWORD} --superuser_password ${ADMIN_PASSWORD}"

    docker-compose exec -T db bash -c "psql -U postgres postgres <<EOF
        \c saleor
        UPDATE public.account_user SET \"email\"='${ADMIN_EMAIL}' WHERE \"email\"='admin@example.com';
    EOF";



    TOKEN=$(curl ${API_URL} \
    -H 'accept: application/json, multipart/mixed' \
    -H 'accept-language: fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7,he;q=0.6,zh-CN;q=0.5,zh;q=0.4,ja;q=0.3' \
    -H 'cache-control: no-cache' \
    -H 'content-type: application/json' \
    -H 'pragma: no-cache' \
    -H 'priority: u=1, i' \
    -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36' \
    --data-raw '{"query":"mutation MyMutation2 {\n  tokenCreate(email: \"'${ADMIN_EMAIL}'\", password: \"'${ADMIN_PASSWORD}'\") {\n    token\n    refreshToken\n    errors {\n      field\n      message\n    }\n  }\n}","operationName":"MyMutation2"}')

    access_token=$(echo $TOKEN | jq -r '.data.tokenCreate.token' )

    curl ${API_URL} \
    -H 'accept: application/json, multipart/mixed' \
    -H 'accept-language: fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7,he;q=0.6,zh-CN;q=0.5,zh;q=0.4,ja;q=0.3' \
    -H 'authorization: Bearer '${access_token}'' \
    -H 'cache-control: no-cache' \
    -H 'content-type: application/json' \
    -H 'pragma: no-cache' \
    -H 'priority: u=1, i' \
    -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36' \
    --data-raw '{"query":"mutation UpdateDomain {\n  shopDomainUpdate(input: {domain: \"'${DOMAIN}':20940\"}) {\n    shop {\n      domain {\n        url\n      }\n    }\n  }\n}\n\n","operationName":"UpdateDomain"}'



    docker-compose down;
    docker-compose up -d;

    touch "./initialized"
fi