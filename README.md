# Convert images into cool abstract circles

## Run with docker

From the root folder:
`docker run -it -v "$(PWD)":/app -p 5000:5000 ruby bash`

From inside the container run:
`cd /app && bundle install && shotgun app.rb -p5000 -o 0.0.0.0`

Now visit http://0.0.0.0:5000 in your host browser And follow the directions.

SVGs and thumbnails will be created in `public/built`
