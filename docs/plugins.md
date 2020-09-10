# sinkholed Plugin Documentation

sinkholed plugins are compiled [go plugins](https://golang.org/pkg/plugin/) compiled with `go build -buildmode=plugin` that get loaded when sinkholed starts up. They can be used to implement downstream data stores, upstream data sources or to carry out filter / middleware operations.

*Note:* If you want to write plugins in a language other than go, see the [API](api.md)


## Plugin configuration

Plugins get their configuration from the main sinkholed [config file](https://github.com/scrapbird/sinkholed#config-file).

Each plugin takes it's own configuration map, defined in the [config/sinkholed.yml](../config/sinkholed.yml) file. The `Plugins` map in the config file contains a map of these individual plugin config definitions, mapped using the name of the plugin file without the extension (`.so`) as the key. This is also how sinkholed knows which plugins to load, you can unload plugins by deleting or commenting out their config maps and restarting the server. Similarly, to tell sinkholed to load a plugin simply add a definition to the config file using the name of the plugin to load as the key.

The configuration is represented by a [viper](https://github.com/spf13/viper) instance that is passed to the plugin's `Init` method. Plugins should [unmarshal](https://godoc.org/github.com/spf13/viper#Unmarshal) their configs into a struct.

Note how the config is used in this example plugin:

```go
package main

import (
    log "github.com/sirupsen/logrus"
    "github.com/scrapbird/sinkholed/pkg/plugin"
    "github.com/spf13/viper"
)

type config struct {
    ExampleVar string
}

type examplePlugin struct {
    plugin.Plugin
    cfg *config
}

func (p *examplePlugin) Init(cfg *viper.Viper, downstream chan<- *core.Event) error {
    // Parse the config
    var c config
    cfg.Unmarshal(&c)
    p.cfg = &c
    
    // ExampleVar can be accessed like so
    log.Println(p.cfg.ExampleVar)

    return nil
}

func (p *examplePlugin) Halt() error {
    return nil
}

// Export the plugin
var Plugin examplePlugin

```


## Logging

sinkholed uses [logrus](https://github.com/sirupsen/logrus) as a logging driver, simply import it inside your plugin and start using it:

```go
// ...

import (
    log "github.com/sirupsen/logrus"
)

// ...

func (p *esPlugin) Init(cfg *viper.Viper, downstream chan<- *core.Event) error {
    log.Infoln("Initializing plugin")
}

// ...
```


## Plugin interfaces

There are three different plugin interfaces a plugin can implement and a base `Plugin` interface that they all have to implement. Any plugin can implement any or all of the three higher level interfaces. For example a plugin could act as an upstream datasource plugin but also act as a filter / middleware plugin and to some middleware operations.

The base `Plugin` interface looks like the following:

```go
// Plugin is the interface that every plugin must implement.
type Plugin interface {
    // Init takes two parameters, the first is a *viper.Viper config object
    // seeded from the plugin config object defined in the sinkholed config
    // file. The second parameter is a channel used to send events downstream
    // and into the sinkhole.
    Init(*viper.Viper, chan<- *core.Event) error
    // Halt should be implemented by every plugin even if it isn't required. This is
    // where the plugin should clean up any used resources (close DB connections etc).
    Halt() error
}
```

### UpstreamPlugin

An upstream plugin is a plugin that provides data. It has no special features and every plugin in sinkholed is implicitly an `UpstreamPlugin`. This is because every plugin's `Init` method is passed a go channel that sinkholed [events](#the-event-object) can be piped into. Any plugin that wishes to act as an upstream plugin should keep a reference to this channel.

```go
// UpstreamPlugin is the interface that every upstream plugin 
// (plugin that produces events) must implement.
type UpstreamPlugin interface {
    Plugin
}

```

### DownstreamPlugin

A downstream plugin is a plugin that wants to know about each event, possibly to store the data in some backend storage such as elasticsearch. Any plugin that implements the [DownstreamPlugin interface](https://github.com/scrapbird/sinkholed/blob/master/pkg/plugin/plugin.go#L112) is passed each event by sinkholed through it's `Inbox` method. A `DownstreamPlugin` has the following signature:

```go
// DownstreamPlugin is the interface that every downstream plugin 
// (plugin that consumes events) must implement.
type DownstreamPlugin interface {
    Plugin
    // Inbox is used to pass events to downstream plugins. This should be implemented
    // by all plugins wishing to act as a downstream plugin.
    Inbox(event *core.Event) error
}
```

### MiddlewarePlugin

A middleware plugin acts as middleware to either drop or alter events before they are passed to the [downstream](#DownstreamPlugin)  plugins. It should implement the following interface:

```go
// MiddlewarePlugin is the interface that every middleware plugin 
// (plugin that filters or changes events before being sent downstream)
// must implement.
type MiddlewarePlugin interface {
    Plugin
    FilterEvent(event *core.Event) (*core.Event, error)
}
```

The `FilterEvent` method takes an event as input, and provides an event as output. To drop an event so that sinkholed doesn't pass it to the [downstream plugins](#DownstreamPlugin) simply return `nil`. To alter an event (for example to add metadata to the event after doing some analysis) just return a modified version of the event passed in to the function.

## The event object

Every event passed through sinkholed has the following schema:

```go
import (
    "time"
)

// The type used to represent a binary sample file.
type Sample struct {
    // Binary representation of the sample file
    Data []byte `json:"data"`
    // Sha256 of the Data
    Sha256 string `json:"sha256"`
}

// Metadata is defined as an interface{} so that we can use any method for attaching 
// metadata to an event. For example, an array of string tags or a more complicated map
// of data.
type Metadata interface{}

// The type that is used to represent events passed through the sinkhole.
type Event struct {
    // This string should indicate the type of event, 'email', 'dropped file' etc.
    Type string `json:"type"`
    // A time stamp of the time the event happened
    Timestamp time.Time `json:"timestamp"`
    // An array of samples, (attachments, the file dropped etc).
    Samples []Sample `json:"samples"`
    // The source of the event, (name of the plugin that generated the event, unenforced)
    Source string `json:"source"`
    // Any metadata about the event, an array of tags or a more complicated map detailing 
    // the botnet it came from etc etc
    Metadata Metadata `json:"metadata"`
}
```

This is defined in [github.com/scrapbird/sinkholed/pkg/core/core.go](../pkg/core/core.go).

