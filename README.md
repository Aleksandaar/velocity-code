Showcase Code
=============

### Showcase code is consisted of: ###

### APPs:

<ol>
  <li>Streaming App - A fraction of a user streaming app, generating user content and streaming it to the live watchers</li>
  <li>Calendar App - User scheduling events between teaches and students</li>
  <li>Book App - Book finder app</li>
</ol>

### Additional examples:

<ol>
  <li>Group Event - Represents a usage of API, creating needed model, controller, and working with TDD approach</li>
  <li>Additional examples - Additional examples of models and their specs in Rails</li>
  <li>Rails and Angular - Small fraction of Rails and Angular app</li>
</ol>

<hr/>
* <em>Examples are modified slightly to be unusable in real-life usage. This is for representational purposes only. </em>

# Streaming app #

Description:

> This is a live stream app which allows user to live stream video from their mobile phones to their followers who can watch their live broadcast on a web-page (like watching live news).

# Group Event app #

Description of the part of the app:

> A group event will be created by an user. The group event should run for a whole number of days e.g.. 30 or 60. There should be attributes to set and update the start, end or duration of the event (and calculate the other value). The event also has a name, description (which supports formatting) and location. The event should be draft or published. To publish all of the fields are required, it can be saved with only a subset of fields before it’s published. When the event is deleted/remove it should be kept in the database and marked as such.

Code sample consists of:

> An AR model, spec and migration for a GroupEvent that meets the needs of the description above. The api controller and spec to support JSON request/responses to manage these GroupEvents. For this purposes auth is ignored. The example is showing building the API without the `jbuilder`.


# Additional examples #

The sample code of different testing approaches. Only tests and a relevant model are shown.


# Rails and Angular #

The code represents only a small fraction of Rails + Angular app - only the `Directive` and a `Controller`. Other parts which are not included consists of other services, state providers and relevant Rails API calls which are used in the app.

The Angular code structure can be seen in the [image](rails_and_angular/images/angular-code-structure.png)
