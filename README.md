# CYTY

### Quick Start
The explanations for the `make` commands are inside Makefile
- start docker on your machine
- run `make dcup`
- run `make mup`
- run `make run`


### Running "make dcup"
If you have issues running make dcup, remove all containers and volumes, then run `make dcup` again. Step by step:
- stop all containers
- docker rm -f $(docker ps -a -q)
- docker volume rm $(docker volume ls -q)
- run migrations with `make mup`

### Modify the postgres config

- make itbash
- vi /var/lib/postgresql/data/postgresql.conf (this opens up vim)
- docker restart <servicename>