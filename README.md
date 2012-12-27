Songride is an application which generates per-user statistics from which
country the artists are coming from that were played.

It made up of several components:

1. NodeJS web interface written in CoffeeScript for user interaction and
   data visualization
2. Queue using Kue and Redis to fetch data from Last.fm and The Echonest
3. MongoDB storage for all data except the queue.

Setup
-----

Just install async, bower and coffeescript using

```
npm install -g coffee-script bower
npm install async
```

and then all other dependcies are fetched and built using

```
cake update
```

Use `config.json.dist` as a template to build your custom `config.json`.
