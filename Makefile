SHELL := /bin/bash

include .envrc


# ==================================================================================== # 
# HELPERS
# ==================================================================================== #

## help: print this help message
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'

confirm:
	@echo -n 'Are you sure? [y/N] ' && read ans && [ $${ans:-N} = y ]

.PHONY: help confirm run build start dup credb cremig mversion mup mdown mdownone itdb audit vendor connect deploy


# ==================================================================================== # 
# DEVELOPMENT
# ==================================================================================== #

run:
	go run ./cmd/api/ -db-dsn=${DSN}

build:
	go build -ldflags="-s -w" -o=./bin/api ./cmd/api
	GOOS=linux GOARCH=arm64 go build -ldflags="-s -w" -o=./bin/linux_arm64/api ./cmd/api

start:
	./bin/api -port=4001 -db-dsn=${DSN} -limiter-enabled=false

version:
	go run ./cmd/api/ -version

dcup:
	docker-compose up --build -d


# ==================================================================================== # 
# DATABASE
# ==================================================================================== #

## cremig: create migration; needs an argument name=custom_migration_name
cremig:
	migrate create -seq -ext=.sql -dir=./migrations ${name}

mversion:
	migrate -path migrations -database ${DSN} version

mup:
	migrate -path migrations -database ${DSN} -verbose up 

mdown: confirm
	migrate -path migrations -database ${DSN} -verbose down

mdownone: confirm
	migrate -path migrations -database ${DSN} -verbose down 1

itdb:
	docker exec -it listingsservice psql -U ${POSTGRES_USER}


# ==================================================================================== # 
# QUALITY CONTROL
# ==================================================================================== #

## audit: tidy dependencies and format, vet and test all code; needs staticcheck installed
audit: vendor
	@echo 'Formatting code...'
	go fmt ./...
	@echo 'Vetting code...'
	go vet ./...
	staticcheck ./...
	@echo 'Running tests...'
	go test -race -vet=off ./...

## vendor: tidy and vendor dependencies
vendor:
	@echo 'Tidying and verifying module dependencies...' 
	go mod tidy
	go mod verify
	@echo 'Vendoring dependencies...'
	go mod vendor


# ==================================================================================== # 
# PRODUCTION
# ==================================================================================== #

production_host_ip = '128.140.93.230'

rootconnect:
	ssh root@${production_host_ip}

## production/connect: connect to the production server
connect:
	ssh listings@${production_host_ip}

deploy:
	rsync -P ./bin/linux_arm64/api listings@${production_host_ip}:~
	rsync -rP --delete ./migrations listings@${production_host_ip}:~
	rsync -P ./remote/production/api.service listings@${production_host_ip}:~
	rsync -P ./remote/production/Caddyfile listings@${production_host_ip}:~
	ssh -t listings@${production_host_ip} 'migrate -path ~/migrations -database $$DSN up && sudo mv ~/api.service /etc/systemd/system/ && sudo systemctl enable api && sudo systemctl restart api && sudo mv ~/Caddyfile /etc/caddy/ && sudo systemctl reload caddy'	

# prod deploy old deploy code
#deploy:
#	rsync -P ./bin/linux_arm64/api listings@${production_host_ip}:~
#	rsync -rP --delete ./migrations listings@${production_host_ip}:~
#	ssh -t listings@${production_host_ip} 'migrate -path ~/migrations -database $$DSN up'