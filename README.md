# FFSwift

A description of this package.


## Integration tests
The Flickr module has integration tests were communications with Flickr is made. This requires API keys to be passed, and they are expected to be found in your environment variables. If they do not exist, the integration tests will fail

### With .env file
Create a `.env` file to save you from trouble each time. Copy the `.env.example` file and add your values. Before running the tests, run
```bash
export $(grep -v '^#' .env | xargs)
```
to export the variables.

Then run the tests using 
```bash
swift test --filter FFSwiftTests.FlickrTest
```