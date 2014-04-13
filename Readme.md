#Knod

Knod is a lightweight HTTP server designed to facilitate front end development when the corresponding back end is missing or incomplete. It responds to GET, PUT, POST, and DELETE, serving up, writing to, and deleting from the directory of your choosing.

## Installation

```gem install knod```

## Usage

The Knod gem comes with an executable; you can run it from the command line with `knod`. Knod will default to port 4444 and the current directory. You can change these with command line arguments (-p and -d, respectively).

You can also run it by requiring `knod` and calling `Knod.start`. Knod accepts an options hash that lets you change the port and directory:

```ruby
options = {port: 1234, directory: 'some/directory'}
Knod.start options
```

GET requests map suffixes into MIME types. Data is considered to be `application/octet-stream` if the content type is unrecognized.

All data from PUT and POST requests is stored as JSON. If the pathway specified in the request does not exist, Knod will create it.

POST requests auto-increment in the specified path and return the id of the file written as JSON (e.g if a POST request led to the server writing 56.json, the server would respond with `"{\"id\":56}"`.

