#Knod

[![Gem Version](https://badge.fury.io/rb/knod.svg)](http://badge.fury.io/rb/knod) [![Build Status](https://travis-ci.org/moserrya/knod.svg?branch=master)](https://travis-ci.org/moserrya/knod) [![Code Climate](https://codeclimate.com/github/moserrya/knod.png)](https://codeclimate.com/github/moserrya/knod)

Knod is a simple HTTP server for prototyping rich JavaScript apps. It responds to GET, PUT, POST, PATCH, and DELETE, serving up, writing to, and deleting from the directory of your choice. Knod has no dependencies outside of the Ruby standard library.

## Installation

```gem install knod```

## Usage

The Knod gem comes with an executable; you can run it from the command line with `knod`. Knod will default to port 4444 and the current directory. You can change these with command line arguments (-p and -d, respectively).

You can also run it by requiring `knod` and calling `Knod.start`. Knod accepts an options hash that lets you change the port, root directory, and logging:

```ruby
options = {port: 1234, root: './some/directory', logging: false}
Knod.start options
```

Logging is enabled by default. The server will select an open ephemeral port at random if you pass in 0 as the port.

Knod sanitizes the path on all requests and does not allow access to folders outside of the root directory where it is run.

GET requests map suffixes into MIME types. Data is considered to be `application/octet-stream` if the content type is unrecognized.

All data from PUT, POST, and PATCH requests is stored as JSON. If the pathway specified in the request does not exist, Knod will create it.

POST requests auto-increment in the specified path and return the id of the file written as JSON (e.g if a POST request led to the server writing 56.json, the server would respond with `"{\"id\":56}"`.

