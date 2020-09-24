docker container kill wiki
docker container rm wiki
docker run \
    --name wiki  \
    --restart unless-stopped  \
    -e "DB_TYPE=sqlite"  \
    -e "DB_FILEPATH=/wiki-database/db.sqlite"  \
    --mount type=bind,source="/mnt/a/wiki/data",target=/wiki-files \
    --mount type=bind,source="/mnt/a/wiki",target=/wiki-database \
    -e VIRTUAL_HOST="dox" \
    -p 3005:3000 \
    -d \
    mackay-mfg/wiki