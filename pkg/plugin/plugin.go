// This package contains the implementation of the plugin system for extending sinkholed.
//
// A sinkholed plugin is just a go plugin. A go plugin should reside in the main package
// and implement at least the Plugin interface as defined in this package.
//
// There are three kinds of plugins in sinkholed:
//
// Downstream plugins:
// Plugins that recieve events. These plugins could be used to broadcast events to other
// services, store events etc.
//
// Upstream plugins:
// Plugins that produce events to be consumed by downstream plugins. These plugins make use
// of the event channel passed into their Init method, piping all events they produce into
// it. This will cause the event to be consumed and processed by sinkholed.
//
// Middleware plugins:
// Plugins that filter or change events. These act like middleware and can be used to drop
// events, causing them to not be processed or modify events to do actions such as adding
// extra metadata or removing unwanted data.
//
// Any plugin can implment more than one or all of the previously described interfaces and
// sinkholed will automatically figure out what capability the plugin has. This means that a
// single plugin can act as an upstream, downstream and milddleware plugin all at once.
//
// To load a plugin, define a configuration object in the "Plugins" map in the sinkholed
// config file, using the plugin file name without the extension plugin as the key. Example:
//
//  Plugins:
//    "pluginName":
//      ConfigVariable: config value
//
// The configuration object (stored in the main sinkholed config file in the "Plugins" map)
// will be passed to the plugin Init function as a *viper.Viper config object. Included in
// this map will also be two extra values: `LogPath`, which is the path to be used for the 
// log file, and `LogLevel`, which is the log level to use. This can be overridden if you 
// provide a value for LogPath in your plugin's config.
//
// An example plugin is shown below:
//
//  package main
//
//  import (
//      log "github.com/sirupsen/logrus"
//
//      "github.com/spf13/viper"
//  
//      "github.com/scrapbird/sinkholed/pkg/core"
//      "github.com/scrapbird/sinkholed/pkg/plugin"
//  )
//  
//  type demo struct {
//      plugin.Plugin
//      cfg *viper.Viper
//      downstream chan *core.Event
//  }
//  
//  func (p *demo) Init(cfg *viper.Viper, downstream chan *core.Event) error {
//      log.Println("Initializing demo plugin")
//      p.downstream = downstream
//      return nil
//  }
//  
//  func (p *demo) Halt() error {
//      return nil
//  }
//
//  func (p *demo) Inbox(event *core.Event) error {
//      log.Println("New event:", event)
//      return nil
//  }
//  
//  // Export the plugin
//  var Plugin demo
//
// To compile this plugin:
//
//  go build -buildmode=plugin -o main.so main.go
package plugin

import (
    "plugin"
    "sync"
    log "github.com/sirupsen/logrus"

    "github.com/spf13/viper"

    "github.com/scrapbird/sinkholed/internal/config"
    "github.com/scrapbird/sinkholed/pkg/core"
)

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

// UpstreamPlugin is the interface that every upstream plugin 
// (plugin that produces events) must implement.
type UpstreamPlugin interface {
    Plugin
}

// DownstreamPlugin is the interface that every downstream plugin 
// (plugin that consumes events) must implement.
type DownstreamPlugin interface {
    Plugin
    // Inbox is used to pass events to downstream plugins. This should be implemented
    // by all plugins wishing to act as a downstream plugin.
    Inbox(event *core.Event) error
}

// MiddlewarePlugin is the interface that every middleware plugin 
// (plugin that filters or changes events before being sent downstream)
// must implement.
type MiddlewarePlugin interface {
    Plugin
    FilterEvent(event *core.Event) (*core.Event, error)
}

// PluginManager manages plugins and handles the flow of events through
// them.
type PluginManager struct {
    cfg          *config.Config
    plugins      []Plugin
    eventChannel chan *core.Event
    running bool
}

// Creates a new plugin manager.
func NewPluginManager(cfg *config.Config) *PluginManager {
    pm := PluginManager{
        cfg:     cfg,
        plugins: make([]Plugin, 0),
        eventChannel: make(chan *core.Event),
    }
    return &pm
}

// Initialize the plugin manager. This starts processing incoming events.
func (pm *PluginManager) Init() {
    go func() {
        for event := range pm.eventChannel {
            log.Debugln("Emitting event:", event)
            pm.EmitEvent(event)
        }
        log.Println("Event channel closed.")
    }()
}

// Loads a plugin from a *.so file.
func (pm *PluginManager) LoadPlugin(pluginPath string, pluginConfig *viper.Viper) {
    log.Println("Loading plugin:", pluginPath)
    p, err := plugin.Open(pluginPath)
    if err != nil {
        log.Errorln("Couldn't open plugin " + pluginPath, err)
        return
    }

    // Lookup plugin exports
    symPlugin, err := p.Lookup("Plugin")
    if err != nil {
        log.Errorln("Couldn't load plugin exports:", err)
        return
    }

    // Assert plugin type
    var plugin Plugin
    plugin, ok := symPlugin.(Plugin)
    if !ok {
        log.Errorln("Invalid plugin type:", pluginPath)
        return
    }

    // Initialize plugin
    err = plugin.Init(pluginConfig, pm.eventChannel)
    if err != nil {
        log.Errorf("Failed to initialize plugin %s: %s\n", pluginPath, err)
        return
    }

    pm.plugins = append(pm.plugins, plugin)
}

// Halts all loaded plugins.
func (pm *PluginManager) HaltAllPlugins() {
    var wg sync.WaitGroup
    wg.Add(len(pm.plugins))
    for _, plugin := range pm.plugins {
        go func(plugin Plugin) {
            defer wg.Done()
            plugin.Halt()
        }(plugin)
    }
    wg.Wait()
}

// Sends an event through all middleware plugins for filtering / modification
func (pm *PluginManager) filterEvent(event *core.Event) *core.Event {
    for _, plugin := range pm.plugins {
        p, ok := plugin.(MiddlewarePlugin)
        if ok {
            // This is a middleware plugin.
            var err error
            if event, err = p.FilterEvent(event); err != nil {
                log.Errorln("Error during middleware filtering in plugin", err)
            }
        }
    }
    return event
}

// Sends an event to all downstream plugins.
func (pm *PluginManager) EmitEvent(event *core.Event) {
    event = pm.filterEvent(event)
    if event != nil {
        for _, plugin := range pm.plugins {
            go func(plugin Plugin) {
                // Assert plugin type.
                p, ok := plugin.(DownstreamPlugin)
                if ok {
                    // This is a downstream plugin.
                    p.Inbox(event)
                }
            }(plugin)
        }
    }
}
