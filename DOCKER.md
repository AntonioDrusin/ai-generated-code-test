# Docker Compose for Local Development

## PostgreSQL Database

Start a local PostgreSQL instance for development:

```bash
# Start PostgreSQL
docker-compose up -d

# View logs
docker-compose logs -f postgres

# Stop PostgreSQL
docker-compose down

# Stop and remove data
docker-compose down -v
```

## Database Connection Details

- **Host**: `localhost`
- **Port**: `5432`
- **Database**: `music_stream_dev`
- **User**: `music_api`
- **Password**: `music_api_password`

## Connection String

```
postgresql://music_api:music_api_password@localhost:5432/music_stream_dev
```

## Verify Database

```bash
# Connect using psql (if installed)
psql -h localhost -U music_api -d music_stream_dev

# Or using docker exec
docker exec -it lang-compare-postgres psql -U music_api -d music_stream_dev
```

## Notes

- Data is persisted in a Docker volume `lang-compare_postgres_data`
- The `init-db.sql` file runs on first startup to initialize the database
- Health checks ensure the database is ready before connections
