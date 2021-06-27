---
title: API Reference

language_tabs: # must be one of https://git.io/vQNgJ

- javascript: Javascript
- csharp: C#

toc_footers:

- <a href='https://github.com/slatedocs/slate'>Documentation Powered by Slate</a>

includes:

- contact

search: true

code_clipboard: true
---

# Introduction

The LiveTL REST API is intended to be used for long-term, permanent, storage of translations, while providing real-time
updates (via [Server Sent Events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events)) to clients for
new translations, as they are added.

The primary data served by the API is publicly available, however we ask that you don't attempt to scrape all our data,
if you'd like a datadump of our translations, please [get in touch](#contact-us).

## Examples

We've written example code for the primary scenario of each endpoint, available in both Javascript and C#.

The examples have been written and tested with specific environments in mind; Javascript in the browser (though most
should work in NodeJS with no additional packages) and C# on .NET Core 3.1
(using [RestSharp](https://www.nuget.org/packages/RestSharp), and the (currently internal) `LiveTL.Common` class
library).

If an endpoint requires specific additional packages, it will be explicitly mentioned in a comment of the example code
for that endpoint.

# Caching

## Server

The API employs caching in an attempt to decrease response time when loading translations. This cache is automatically
updated when adding new translations (but only on videos that are already stored in cache), but is ***not*** updated
when modifying or deleting existing translations. The cache currently has a default expiry time of 5 minutes after the
last read, with a maximum lifetime of 1 hour.

## Client

The client is expected to maintain a local cache of certain data to prevent excessive network traffic to/from the API.
Note that you are not expected to bundle this data into the package or webpage you provide to your users, but rather
have each instance of the client send a request to the server on initialization, and then store it on their machine.

### Languages

Clients should maintain a local list of the [ISO 639-1 Language Codes](https://en.wikipedia.org/wiki/ISO_639-1)
supported by the API. This list should be [obtained](#languages) ***once*** by the client and stored on the user's
machine.

The only time a client should request this list again, is if for some reason the API sends a language code that the
client does not recognize from it's internal list. However, this should almost never happen, as the API has been
pre-populated with nearly every language code, and the data is not expected to ever be updated.

### Translators

Clients should store a local list of translators the client has seen. An easy (but not necessary) way to pre-populate
this list is to [get all registered translators](#get-all-registered-translators). Clients should send a request
to [get translator information](#get-translator-by-id) when they encounter a translator ID that is not in their local
list.

# Authentication

> Raw HTTP Header

```http
Authorization: Bearer {your_access_token}
```

> Language-specific examples

```javascript
let response = await fetch("https://api.livetl.app/some/endpoint/with/auth", {
  headers: {
    "Authorization": "Bearer {your_access_token}"
  }
});
```

```csharp
RestClient client = new RestClient("https://api.livetl.app/some/endpoint/with/auth");
RestRequest request = new RestRequest(Method.GET);
request.AddHeader("Authorization", "Bearer {your_access_token}");
IRestResponse response = await client.ExecuteAsync(request);
```

<aside class="notice">
If you're an existing third party service wishing to create an integration with full access to the API, you can request 
access to our Auth0 service to allow users to authenticate within your application by <a href="/#contact-us">contacting us</a>.
</aside>

Not every endpoint requires authentication, most notably the translations and translators endpoints, those that do
require authentication will indicate so in their description.

You're able to authenticate with the API using the same user accounts as used on [our website](https://livetl.app), and
uses [JSON Web Tokens](https://jwt.io/introduction/) to authenticate with the API. You can obtain the JWT Access Token
required to authenticate with the API by using an [Auth0 Library](https://auth0.com/docs/libraries) to sign in to your
LiveTL account.

## Permissions and roles

Most endpoints are restricted behind different permissions (which are assigned to roles, which are assigned to users) so
that only authorized users can access them. If an endpoint requires a specific permission, it will be explicitly stated
in the description of that endpoint.

The following table describes each permission, along with what role has what permissions. The list will likely be
updated and expanded upon as the API continues development.

Permission | Roles | Description
---------- | ----- | -----------
`create:translations` | Registered, Verified | Allows the user to create new translations on videos
`modify:translations` | Registered, Verified | Allows the user to modify (change or delete) their own translations
`write:translations` | Verified | Allows the user to modify (change or delete) translations from any translator

# Translations

## Get All Translations on a Video

```javascript
let response = await fetch("https://api.livetl.app/translations/example/en");
let translations = await response.json();
```

```csharp
RestClient client = new RestClient("https://api.livetl.app/translations/example/en");
RestRequest request = new RestRequest(Method.GET);
IRestResponse response = await client.ExecuteAsync(request);
List<TranslationModel> translations = JsonSerializer.Deserialize<List<TranslationModel>>(response.Content, new JsonSerializerOptions {
    PropertyNameCaseInsensitive = true
});
```

> The endpoint returns a list of JSON objects like this:

```json
[
  {
    "id": 1,
    "videoId": "example",
    "translatorId": "auth0|60c195aa5d89a500699c01cc",
    "languageCode": "en",
    "translatedText": "This is an example translation",
    "start": 1,
    "end": null
  },
  {
    "id": 2,
    "videoId": "example",
    "translatorId": "auth0|60c195aa5d89a500699c01cc",
    "languageCode": "en",
    "translatedText": "This is a second example translation, with a specific end timestamp",
    "start": 150,
    "end": 175
  }
]
```

Returns all translations (with the specified filter, if any) for a specific video.

See the [SSE endpoint](#receive-new-translations-on-a-video) for the recommend endpoint to receive translations during
a live stream.

### HTTP Request

`GET https://api.livetl.app/translations/{video_id}/{language_code}`

### URL Parameters

Parameter | Description
--------- | -----------
video_id | The YouTube Video ID (ie `dQw4w9WgXcQ` from `https://www.youtube.com/watch?v=dQw4w9WgXcQ`) to get translations for
language_code | The [ISO 639-1 language code](https://en.wikipedia.org/wiki/ISO_639-1) of the language to get translations in

### Query Parameters (Filters)

Parameter | Default | Description | Constraints
--------- | ------- | ----------- | -----------
since | `-1` | Only returns translations created after this timestamp (in ms from start of stream) | None
require | `null` | Only returns translations created by the specified translator(s) | A comma separated list of Translator IDs -- Mutually exclusive with `exclude`
exclude | `null` | Don't return translations created by the specified translator(s) | A comma separated list of Translator IDs -- Mutually exclusive with `require`

### Possible HTTP Response Status Codes

Code | Description
---- | -----------
200 OK | The API found and returned translations in the requested language for the requested video, and with the specified filters
404 Not Found | The API wasn't able to find any translations in the requested language for the requested video, with the specified filters
400 Bad Request | You provided both a `require` and `exclude` filter
400 Bad Request | You requested an unknown language code

## Receive New Translations on a Video

```javascript
// Requires the `eventsource` npm package when using NodeJS
let source = new EventSource("https://api.livetl.app/translations/stream?videoId=testid");
source.onmessage = msg => {
  console.log(msg.data);
}
```

```csharp
// The C# example has not yet been written, as .NET Core does not include a native way to consume SSE
// When the example is written, it will likely use the `LaunchDarkly.EventSource` nuget package 
```

> The endpoint streams JSON objects like this:

```json
{
  "id": 1,
  "videoId": "example",
  "translatorId": "auth0|60c195aa5d89a500699c01cc",
  "languageCode": "en",
  "translatedText": "This is an example translation",
  "start": 1,
  "end": null
}  
```

A [Server Sent Events (SSE)](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events) endpoint to allow
clients to use an [EventSource](https://developer.mozilla.org/en-US/docs/Web/API/EventSource) receive new translations
for a language on a requested video immediately when they are created.

<aside class="notice">
This is the recommended way for clients to receive translations during a live stream.
</aside>

### Event Source URL

`https://api.livetl.app/translations/stream?videoId={video_id}?languageCode={language_code}`

### URL Parameters

Parameter | Description
--------- | -----------
video_id | The YouTube Video ID (ie `dQw4w9WgXcQ` from `https://www.youtube.com/watch?v=dQw4w9WgXcQ`) to get translations for
language_code | The [ISO 639-1 language code](https://en.wikipedia.org/wiki/ISO_639-1) of the language to get translations in

### Possible connection initialization responses

Code | Description
---- | -----------
CONNECTED | The API registered your connection to receive all new translation in the requested language on the requested video
ERROR | You didn't provide a Video ID
ERROR | You didn't provide a Language Code
ERROR | You provided an invalid Language Code

<aside class="warning">
This endpoint does not provide any method for server-side filtering, as such if you require filtering, it <i>must</i> be done client side.
</aside>

## Add Translation to Video

> This endpoint requires [Authorization](#authentication) with the `create:translations` permission

```javascript
let response = await fetch("https://api.livetl.app/translations/example", {
  method: "POST",
  headers: {
    "Authorization": "Bearer {your_access_token}",
    "Content-Type": "application/json"
  },
  body: JSON.stringify({
    "translatedText": "This is an example translation",
    "start": 150,
    "languageCode": "en"
  })
});
let success = response.status === 201;
```

```csharp
RestClient client = new RestClient("https://api.livetl.app/translations/example");
RestRequest request = new RestRequest(Method.POST);
request.AddHeader("Authorization", $"Bearer {your_access_token}");
request.AddHeader("Content-Type", "application/json");
request.AddJsonBody(new TranslationModel {
    TranslatedText = "This is an example translation",
    Start = 150,
    LanguageCode = "en"
});
IRestResponse response = await client.ExecuteAsync(request);
bool success = response.IsSuccessful;
```

Add a new translation to a video. The API expects a valid (see 'Request Body' section below) JSON object in the body of
the request. Property names are not case sensitive.

This endpoint requires [Authorization](#authentication) with the `create:translations` permission.

### HTTP Request

`POST https://api.livetl.app/translations/{video_id}`

### Request Body

Property | Required | Description | Constraints
-------- | -------- | ----------- | -----------
LanguageCode | Yes | The language the translation is for | Valid [ISO 639-1 language code](https://en.wikipedia.org/wiki/ISO_639-1)
TranslatedText | Yes | The translation itself | Non-empty string
Start | Yes | The timestamp (in milliseconds) to display the translation at | 32-bit integer, greater than or equal to 0
End | No | The timestamp (in milliseconds) to stop displaying the translation at. Useful for clients that display translations as a caption on the video, or for exporting to a subtitle format (such as SRT or ASS) | 32-bit integer, greater than `Start`

### URL Parameters

Parameter | Description
--------- | -----------
video_id | The YouTube Video ID (ie `dQw4w9WgXcQ` from `https://www.youtube.com/watch?v=dQw4w9WgXcQ`) to add the translation to

Code | Description
---- | -----------
201 Created | The API has added the translation to the database (and cache, if applicable)
400 Bad Request | You didn't include all the required properties in the JSON body
400 Bad Request | You provided an unknown language code, or invalid start/end timestamp
400 Bad Request | The translator who authorized the request has not been registered in the database as a translator, but still somehow has the permission a registered translator does (this is likely a bug, please [contact us](#contact-us) to report it)
500 Server Error | The API encountered an error when adding the translation to the database

# Translators

## Get All Registered Translators

## Get Translator by ID
