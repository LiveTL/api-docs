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

## Attribution

TODO

## Examples

We've written example code for the primary scenario of each endpoint, available in both Javascript and C#.

The examples have been written and tested with specific environments in mind; Javascript in the browser (though most
should work in NodeJS with no additional packages) and C# on .NET Core 3.1 (using the (currently
internal) `LiveTL.Common` class library).

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

This list can be updated periodically so that any newly registered translators, or changes made to translator profiles
are synchronized to the client. This update should be done infrequently if you're using the
[get all registered translators](#get-all-registered-translators) endpoint, preferably no more than once per day, but
updating individual translators as you require their information can be done much more frequently, and thus should be
the primary methods clients should use.

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
using HttpClient client = new HttpClient();
client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", {your_access_token});
HttpResponseMessage response = await _client.GetAsync("https://api.livetl.app/some/endpoint/with/auth");
```

<aside class="notice">
If you're an existing third party service wishing to create an integration with full access to the API, you can request 
access to our Auth0 service to allow users to authenticate within your application by <a href="/#contact-us">contacting us</a>.
</aside>

Not every endpoint requires authentication, most notably the get translations and get translators endpoints. Endpoints
that do require authentication will indicate so in their description. When requesting without a valid authorization
token present or the user does not have the required permission node for the endpoint, the API will return a
`403 - Forbidden` status.

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

## Overview

The translation object sent by the API contains the minimum amount of information needed, and the client is expected to
look up (preferably using it's local cache) information about the translator and language.

Note that translations contain both a start and an end time. This is so that translations can be exported into standard
subtitle formats (such as [SRT](https://en.wikipedia.org/wiki/SubRip) or
[SSA/ASS](https://en.wikipedia.org/wiki/SubStation_Alpha)) or be displayed over a video player, should clients choose to
implement that. However, translations that were added while a stream was live will not include an end time, and clients
requiring one to be present should ensure to use a default value of some sort. When adding (or updating) translations
after a stream has ended, clients should ensure that a user enters an end time.

The translation object contains the following properties:

Property | Type | Description
-------- | ---- | -----------
Id | 64-bit integer | The unique identifier for the translation
VideoId | string | The ID of the YouTube video this translation is for
TranslatorId | string | The ID of the translator who submitted the translation
LanguageCode | string | The [ISO 639-1 language code](https://en.wikipedia.org/wiki/ISO_639-1) of the language being translated to
TranslatedText | string | The actual text content of the translation
Start | 32-bit integer | The timestamp (in milliseconds) the translation starts at
End | 32-bit integer | The timestamp (in milliseconds) the translation starts at

## Get All Translations on a Video

```javascript
let response = await fetch("https://api.livetl.app/translations/example/en");
let translations = await response.json();
```

```csharp
using HttpClient client = new HttpClient();
HttpResponseMessage response = await client.GetAsync("https://api.livetl.app/translations/example/en");
List<TranslationModel> translations = JsonSerializer.Deserialize<List<TranslationModel>>(await response.Content.ReadAsStringAsync(), new JsonSerializerOptions {
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

See the [SSE endpoint](#receive-new-translations-on-a-video) for the recommend endpoint to receive translations during a
live stream.

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
since | `-1` | Only returns translations created after this timestamp (in milliseconds from start of stream) | 32-bit integer
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
let source = new EventSource("https://api.livetl.app/notifications/translations?videoId=example&languageCode=en");
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

A [Server Sent Events (SSE)](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events) endpoint that allows
clients to use an [EventSource](https://developer.mozilla.org/en-US/docs/Web/API/EventSource) to receive new
translations for a language on a requested video, immediately when they are created.

<aside class="notice">
This is the recommended way for clients to receive translations during a live stream.
</aside>

### Event Source URL

`https://api.livetl.app/notifications/translations?videoId={video_id}&languageCode={language_code}`

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
using HttpClient client = new HttpClient();
client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", {your_access_token});
StringContent content = new StringContent(JsonSerializer.Serialize(new TranslationModel {
    TranslatedText = "This is an example translation",
    Start = 150,
    LanguageCode = "en"
}), Encoding.UTF8, "application/json");
HttpResponseMessage response = await client.PostAsync("https://api.livetl.app/translations/example", content);
bool success = response.IsSuccessStatusCode;
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

### Possible HTTP Response Status Codes

Code | Description
---- | -----------
201 Created | The API has added the translation to the database (and cache, if applicable)
400 Bad Request | You didn't include all the required properties in the JSON body
400 Bad Request | You provided an unknown language code, or invalid start/end timestamp
400 Bad Request | The translator who authorized the request has not been registered in the database as a translator, but still somehow has the permission a registered translator does (this is likely a bug, please [contact us](#contact-us) to report it)
500 Server Error | The API encountered an error when adding the translation to the database

## Update a Translation

> This endpoint requires [Authorization](#authentication) with the `modify:translations` or `write:translations` permissions

```javascript
let response = await fetch("https://api.livetl.app/translations/1", {
    method: "PUT",
    headers: {
        "Authorization": "Bearer {your_access_token}",
        "Content-Type": "application/json"
    },
    body: JSON.stringify({
        "translatedText": "This is a modification to an existing translation"
    })
});
let modifiedOrNotNeccessary = response.status === 204 || response.status === 200;
```

```csharp
using HttpClient client = new HttpClient();
client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", {your_access_token});
StringContent content = new StringContent(JsonSerializer.Serialize(new TranslationModel {
    TranslatedText = "This is a modification to an existing translation"
}), Encoding.UTF8, "application/json");
HttpResponseMessage response = await client.PutAsync("https://api.livetl.app/translations/1");
bool modifiedOrNotNeccessary = response.StatusCode == HttpStatusCode.NoContent || resposne.StatusCode == HttpStatusCode.OK;
```

Modifies an existing translation. The API expects a valid (see 'Request Body' section below) JSON object in the body of
the request. Property names are not case sensitive.

The cache is not immediately updated with modifications made using this endpoint, and may take up to 1 hour to refresh.

This endpoint requires [Authorization](#authentication) with the `modify:translations` or `write:translations`
permissions. Users with `write:translations` can modify any translation, users with `modify:translations` can only
modify their own.

### HTTP Request

`PUT https://api.livetl.app/translations/{translation_id}`

### Request Body

Note that while all properties are optional, at least one property must be set. If other translation properties are
included in the object, they will be ignored and return `200 - No modifications are required`.

Property | Required | Description | Constraints
-------- | -------- | ----------- | -----------
TranslatedText | No | The new translation text | Non-empty string
Start | No | The new timestamp (in milliseconds) to display the translation at | 32-bit integer, greater than or equal to 0
End | No | The new timestamp (in milliseconds) to stop displaying the translation at | 32-bit integer, greater than `Start`

### URL Parameters

Parameter | Description
--------- | -----------
translation_id | The ID of the translation to modify

### Possible HTTP Response Status Codes

Code | Description
---- | -----------
204 No Content | The API has modified the translation specified
400 Bad Request | You didn't include any properties in the JSON body
404 Not Found | A translation does not exist with the specified ID
403 Forbidden | You attempted to modify a translation you don't have permission for
500 Server Error | The API encountered an error when updating the translation in the database

## Delete a Translation

> This endpoint requires [Authorization](#authentication) with the `modify:translations` or `write:translations` permissions

```javascript
let response = await fetch("https://api.livetl.app/translations/1", {
    method: "DELETE",
    headers: {
        "Authorization": "Bearer {your_access_token}",
        "Content-Type": "application/json"
    },
    body: "Innaccurate/troll translation"
});
let deletedOrRequested = response.status === 204 || response.status === 202;
```

```csharp
using HttpClient client = new HttpClient();
client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", {your_access_token});
HttpRequestMessage request = new HttpRequestMessage(HttpMethod.Delete, "https://api.livetl.app/translations/1");
request.Content = new StringContent("Innaccurate/troll translation", Encoding.UTF8, "text/plain");
HttpResponseMessage response = await client.SendAsync(request);
bool deletedOrRequested = response.StatusCode == HttpStatusCode.NoContent || resposne.StatusCode == HttpStatusCode.Accepted;
```

Deletes an existing translation. The API expects a plain-text string in the body of the request for the reason.

The cache is not immediately updated with deletions made using this endpoint, and may take up to 1 hour to refresh.

This endpoint requires [Authorization](#authentication) with the `modify:translations` or `write:translations`
permissions. Users with `write:translations` can delete any translation, users with `modify:translations` can only
delete their own, other translations will have a delete request submitted for review by verified translators.

### HTTP Request

`DELETE https://api.livetl.app/translations/{translation_id}`

### Request Body

A string containing the reason why you are deleting the translation.

### URL Parameters

Parameter | Description
--------- | -----------
translation_id | The ID of the translation to delete

### Possible HTTP Response Status Codes

Code | Description
---- | -----------
204 No Content | The API has deleted the translation specified
202 Accepted | The API has created a deletion request for the translation specified
400 Bad Request | You didn't include a deletion reason
404 Not Found | A translation does not exist with the specified ID
500 Server Error | The API encountered an error when deleting the translation from the database
500 Server Error | The API encountered an error when creating the deletion request for the translation in the database

# Translators

## Overview

The translator object sent by the API contains information about a translator for displaying alongside translations in a
client. The API only responds with information about users who have registered as a translator, and not normal users who
have only signed up for a LiveTL account.

Please be sure to read about the [local caching expectations](#translators) before implementing usage of these endpoints
into your client.

The translator object contains the following properties:

Property | Type | Description
-------- | ---- | ----------
UserId | string | The unique identifier (assigned by Auth0) for the translator
DisplayName | string | The name the translator has set to be displayed by clients
ProfilePictureUrl | string | The URL where the users profile picture (if set) is located at
Type | string | The [translator account type](#account-types) of the translator
Languages | Language[] | An array of [language objects](#languages-2) the translator is registered under

## Account Types

Currently there are only two implemented account types, Registered and Verified. Additional types may be added at some
point in the future, but none are currently planned.

Registered translators are any user who has signed up for a LiveTL account and registered that account as a translator.
LiveTL has no involvement in who can register as a translator, but reserves the right to 'ban' translators who
consistently and intentionally submit low quality or inaccurate translations, as these are potentially harmful to both
streamers and the community.

Verified translators are registered translators who have submitted an application to LiveTL with information that
verifies them as a professional translator, or is recognized and approved by a well-known community official (ie modded
by a streamer they translate for). These translators are typically considered to have higher quality or more accurate
translations than normal registered translators, and as such clients developed by the LiveTL team will differentiate
between the two. Third party clients are not required or expected to differentiate them.

## Get All Registered Translators

```javascript
let response = await fetch("https://api.livetl.app/translators/registered");
let translators = await response.json();
```

```csharp
RestClient client = new RestClient("https://api.livetl.app/translators/registered");
RestRequest request = new RestRequest(Method.GET);
IRestResponse response = await client.ExecuteAsync(request);
List<Translator> translators = JsonSerializer.Deserialize<List<Translator>>(response.Content, new JsonSerializerOptions {
    PropertyNameCaseInsensitive = true
});
```

> The endpoint returns a list of JSON objects like this:

```json
[
  {
    "languages": [
      {
        "code": "en",
        "name": "English",
        "nativeName": "English"
      },
      {
        "code": "ja",
        "name": "Japanese",
        "nativeName": "日本語"
      }
    ],
    "type": "Registered",
    "userID": "auth0|60c195aa5d89a500699c01cc",
    "displayName": "grumpybear4257",
    "profilePictureUrl": "https://s.gravatar.com/avatar/6aaef03e46b8344a9178a565a4ef70e4?s=480&r=pg&d=https%3A%2F%2Fcdn.auth0.com%2Favatars%2Fgr.png"
  },
  {
    "languages": [
      {
        "code": "en",
        "name": "English",
        "nativeName": "English"
      },
      {
        "code": "ja",
        "name": "Japanese",
        "nativeName": "日本語"
      }
    ],
    "type": "Verified",
    "userID": "auth0|60cafad9612d820070a6c388",
    "displayName": "kamishirotaishi",
    "profilePictureUrl": "https://s.gravatar.com/avatar/50202936063379c31b0b03084eb48067?s=480&r=pg&d=https%3A%2F%2Fcdn.auth0.com%2Favatars%2Fka.png"
  }
]
```

Returns all registered translators (including verified).

### HTTP Request

`GET https://api.livetl.app/translators/registered`

### Possible HTTP Response Status Codes

Code | Description
---- | -----------
200 OK | The API found and returned all translators who have registered
404 Not Found | There are no translators who have registered

## Get Translator by ID

```javascript
let response = await fetch("https://api.livetl.app/translators/auth0|60cafad9612d820070a6c388");
let translator = await response.json();
```

```csharp
RestClient client = new RestClient("https://api.livetl.app/translators/auth0|60cafad9612d820070a6c388");
RestRequest request = new RestRequest(Method.GET);
IRestResponse response = await client.ExecuteAsync(request);
Translator translator = JsonSerializer.Deserialize<Translator>(response.Content, new JsonSerializerOptions {
    PropertyNameCaseInsensitive = true
});
```

> The endpoint returns a JSON object like this:

```json
{
  "languages": [
    {
      "code": "en",
      "name": "English",
      "nativeName": "English"
    },
    {
      "code": "ja",
      "name": "Japanese",
      "nativeName": "日本語"
    }
  ],
  "type": "Verified",
  "userID": "auth0|60cafad9612d820070a6c388",
  "displayName": "kamishirotaishi",
  "profilePictureUrl": "https://s.gravatar.com/avatar/50202936063379c31b0b03084eb48067?s=480&r=pg&d=https%3A%2F%2Fcdn.auth0.com%2Favatars%2Fka.png"
}
```

Finds a specific translator, using their User ID.

### HTTP Request

`GET https://api.livetl.app/translators/{user_id}`

### URL Parameters

Parameter | Description
--------- | -----------
user_id | The ID of the user to find

### Possible HTTP Response Status Codes

Code | Description
---- | -----------
200 OK | The API found and returned the translator with the specified ID
404 Not Found | There is no translator with the specified ID

## Register as Translator

> This endpoint requires [Authorization](#authentication)

```javascript
let response = await fetch("https://api.livetl.app/translators/register", {
    method: "POST",
    headers: {
        "Authorization": "Bearer {your_access_token}",
        "Content-Type": "application/json"
    },
    body: JSON.stringify([
        "en", "ja"
    ])
});
let success = response.status === 200;
```

```csharp
StringContent content = new StringContent(JsonSerializer.Serialize(new string[] {
    "en", "ja"
}), Encoding.UTF8, "application/json");
HttpResponseMessage response = await client.PostAsync("https://api.livetl.app/translators/register", content);
bool success = response.IsSuccessStatusCode;
```

Registers a LiveTL Auth0 user as a translator with the API.

This endpoint requires [Authorization](#authentication).

### HTTP Request

`POST https://api.livetl.app/translators/register`

### Request Body

The body of this request is not an object with properties, but rather a single JSON array. Other translator information
required by the API will be retrieved from the Auth0 user information.

Property | Required | Description | Constraints
-------- | -------- | ----------- | -----------
Languages | Yes | The languages the translator is able to translate to/from | JSON Array of [ISO 639-1 Language Codes](https://en.wikipedia.org/wiki/ISO_639-1)

### Possible HTTP Response Status Codes

Code | Description
---- | -----------
200 OK | The API successfully registered the user as a translator
400 Bad Request | You didn't include any translatable languages, or the ones you included are not valid
400 Bad Request | You have already registered as a translator
500 Server Error | The API encountered an error when retrieving user information from Auth0
500 Server Error | The API encountered an error when registering the translator
500 Server Error | The API encountered an error when adding permission roles to the user on Auth0

# Languages

The API uses [ISO 639-1 Languages](https://en.wikipedia.org/wiki/ISO_639-1) as it's list of supported languages, and the
language object is just it's way to represent those.

The language object contains the following properties:

Property | Type | Description
-------- | ---- | ----------
Code | string | The 2-character, unique identifier of the language
Name | string | The name of the language as used in English
NativeName | string | The name of the language as used in that language
