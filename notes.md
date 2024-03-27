```
opam install ocsigen-start
sudo apt-get update
sudo apt-get upgrade
sudo apt get install imagemagick libgmp-dev npm postgresql postgresql-common ruby-sass # optional?
eval $(opam config env)
eliom-distillery -name eliomtut -template client-server.basic
```

I also need to change <host hostfilter="*"> to <host defaulthostname="localhost" hostfilter="*"> in eliomtut.conf.in

installation

compilation

state management

gamearea

creet render and movement

collision detection

