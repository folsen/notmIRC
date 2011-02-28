notmIRC installation guide to get up and running
================================================
Install node.js  
Install npm

Needed to run:
    npm install socket.io
    npm install express
    npm install jade
    npm install ejs
    npm install coffee-script
    npm install mongoose
    npm install forever *this one is for running the server in "production"*

You need a MongoDB database running.  
With OS X: 
    brew install mongodb

Download the source and run it with
    coffee server.coffee
    
    
Server setup (Ubuntu 10.10)
===========================

Starting from a completely bare Ubuntu 10.10 installation I install build essentials and openssl (dependency for Node.js if you want to be able to do SSL). I also install curl and git for use later.
    apt-get install build-essential libssl-dev curl

Then I install Node.js
    wget http://nodejs.org/dist/node-v0.4.1.tar.gz
    tar -xf node-v0.4.1.tar.gz
    cd node-v0.4.1
    ./configure
    make
    sudo make install

When finished with that I shove in npm with the very simple
    curl http://npmjs.org/install.sh | sh

Finally I install MongoDB, the installation page over at mongodb.org says this package might be a bit old and they were right, I got version 1.4.4. But that's good enough for me right now.
    sudo apt-get install mongodb

And then run the above commands from "Needed to run" to install all the necessary packages.

Everything is installed and ready to go. Let's just set up a nice environment so that the application is always going and we can update easily with git.

First download the source
    git clone git://github.com/ique/notmIRC.git
Then because unfortunately forever doesn't support coffeescript we have to compile to js, so go to the notmIRC directory and run

    coffee -c server.coffee
    
Put this in a file, name it (for example) notmirc

    #!/bin/bash
    sudo forever start /<path-to-the-app>/server.js
    
and then do the following
    sudo mv notmirc /etc/init.d/
    sudo chmod +x /etc/init.d/notmirc
    sudo update-rc.d notmirc defaults
    
Now try restaring the server and then check that everything is up and running.