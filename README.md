# CYTY


### Running "make dcup"
If you have issues, remove all containers and volumes, then run `make dcup` again
- stop all containers
- docker rm -f $(docker ps -a -q)
- docker volume rm $(docker volume ls -q)