# sinkholed API Documentation

The API provides a way to submit events to the sinkhole without writing a [plugin](plugins.md). At the moment the API is very simple and only provides a couple routes.


## Authenticating

sinkholed uses JWTs for the API authentication. You can generate a JWT secret and a JWT to use in your requests to the API with [sinkholecli](https://github.com/scrapbird/sinkholed#sinkholecli).

You should pass a valid JWT to sinkholed in the `Authorization` header like so:

```bash
curl -H 'Authorization: Bearer dummy.jwt.token' http://localhost:8080/api/v1/healthcheck
```


## API routes

### POST /api/v1/event

#### On success

**Status code**: 200

**Body**:

```
{
    "message": "ok"
}
```

#### On error

**Status code**: Some status code following the HTTP standard

**Body**:

```
{
    "message": "{{some (hopefully) descriptive error message}}"
}
```

### GET /api/v1/healthcheck

This endpoint can be used to check the health of sinkholed (to be used to automatically check the health of sinkholed)

#### On success

**Status code**: 200

**Body**:

```
{
    "message": "ok"
}
```

#### On error

**Status code**: 503

**Body**:

```
{
    "message": "{{some (hopefully) descriptive error message}}"
}
```

