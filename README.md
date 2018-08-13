# Devpi Server Alpine Docker image

A Docker image based on [Alpine](https://hub.docker.com/_/alpine/) that runs
a [devpi](http://doc.devpi.net) server (*Local PyPI repo & official PyPI Cache*) with a frontend (devpi-web).

> This image uses Alpine as base to be as lite as possible.

## Usage

```bash
$ docker build -t devpi .
$ docker run -d -p 3141:3141 --name devpi devpi:latest
```

or using the [docker-compose.yml](docker-compose.yml) to run with [docker-compose](https://docs.docker.com/compose/)

```bash
$ docker-compose up -d
```

You can access the devpi server at [localhost:3141](http://localhost:3141)

### pip

Use a configuration similar to this in your `~/.pip/pip.conf`:

```ini
[global]
index-url = http://localhost:3141/root/pypi/+simple/
```

### setuptools

Use a configuration similar to this in your `~/.pydistutils.cfg`:

```ini
[easy_install]
index_url = http://localhost:3141/root/pypi/+simple/
```

### pypirc

Use a configuration similat to this in your `~/.pypirc`:

```ini
[distutils]
index-servers =
    local

[local]
repository= http://localhost:3141/user/index
username= user
password= secret
```

This file allows you to register & upload packages to your own repository, without typing your credentials:

```bash
$ python setup.py register -r local
$ python sdist upload -r local
```

*This example assume a user `user` and an index `index` were previously created using the devpi client command*


## Persistence

For devpi to preserve its state across container shutdown and startup you
should mount a volume at `/data`.

```bash
$ docker run -d -v /srv/docker/devpi:/data -p 3141:3141 --name devpi devpi
```

## Security

The first time it runs, the startup script will generate a password for the root
user and store it in `.root_password` in the volume.

For additional security the argument `--restrict-modify root` has been added
so only the root may create users and indexes.

*devpi-cleaner must be run with `--login root` to have authorization to delete packages*

## devpi-client helper

A small helper script is provided to manipulate the running container.
The script will automatically log in as the `root` user for running commands.

```bash
$ docker exec -it devpi devpi-client -h
logged in 'root', credentials valid for 10.00 hours
usage: devpi [-h] [--version] [--debug] [-y] [-v] [--clientdir DIR]
             {quickstart,use,getjson,patchjson,list,remove,user,passwd,login,logoff,logout,index,upload,test,push,install,refresh}
             ...
```

Alternatively, you can start an interactive shell.

```bash
$ docker exec -it devpi devpi-client bash
logged in 'root', credentials valid for 10.00 hours
bash-4.4#
```

## Credits

This project is heavily inspired from various devpi projects found on github, to take the best of both worlds:
* [LordGaav/docker-devpi](https://github.com/LordGaav/docker-devpi)
* [apihackers/docker-devpi](https://github.com/apihackers/docker-devpi)
* [muccg/docker-devpi](https://github.com/muccg/docker-devpi)
* [m-housh/Dockerfiles](https://github.com/m-housh/Dockerfiles/tree/master/devpi-server)
