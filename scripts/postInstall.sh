#set env vars
set -o allexport; source .env; set +o allexport;

#wait until the server is ready
echo "Waiting for software to be ready ..."
sleep 60s;

docker-compose exec -T saleor bash -c "python3 manage.py migrate"

docker-compose exec -T saleor bash -c "python3 manage.py populatedb"

# docker-compose exec -T saleor bash -c "python3 manage.py createsuperuser"