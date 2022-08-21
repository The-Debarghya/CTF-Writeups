# Pedometer-In-Real-World
A simple application that counts number of steps covered by a person.

* Accepts smartphone inbuilt **Accelerometer** data through a web interface and then calculates number of steps, time elapsed and approximate distance covered.
* The Web Interface uses a simple Ruby framework `sinatra`.

### Usage:

* It can be manually cloned and run in local environment with following commands(if Ruby and Bundler are installed):

```bash
git clone https://github.com/The-Debarghya/Pedometer-In-Real-World
bundle config set --local path 'vendor/bundle'
bundle install
bundle exec rackup --port 4567 --env development
```

* Then navigate to `localhost:4567/uploads` in browser to use the application.

**OR**
* Can be run as a docker container with the following command:<br>
`docker run -it --rm -p 4567:4567 -v log:/app/log -v uploads:/app/public/uploads heisenberg8622/pedometer`
