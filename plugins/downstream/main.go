package main

// Sinkholed Downstream Plugin

import (
    "time"
    "bytes"
    "io/ioutil"
    "net/http"
    "strings"
    "encoding/json"

    "github.com/spf13/viper"

    log "github.com/sirupsen/logrus"

    "github.com/scrapbird/sinkholed/pkg/core"
    "github.com/scrapbird/sinkholed/pkg/plugin"
)

type config struct {
    DestAddress string
    Jwt string
    TimeoutSeconds time.Duration
}

type downstreamSinkholed struct {
    plugin.Plugin
    cfg *config
}

func (p *downstreamSinkholed) Init(cfg *viper.Viper, downstream chan<- *core.Event) error {
    log.Println("Initializing downstreamSinkholed plugin")

    // Enable env variable overrides
    cfg.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
    cfg.SetEnvPrefix("SINKHOLED_DOWNSTREAM")
    cfg.AutomaticEnv()

    // Set default timeout seconds
    cfg.SetDefault("TimeoutSeconds", 30)

    // Workaround for viper not reading keys from env unless they are manually Get'd
    cfg.Set("DestAddress", cfg.Get("DestAddress"))
    cfg.Set("Jwt", cfg.Get("Jwt"))
    cfg.Set("TimeoutSeconds", cfg.Get("TimeoutSeconds"))

    // Parse the config
    var c config
    cfg.Unmarshal(&c)
    p.cfg = &c

    return nil
}

func (p *downstreamSinkholed) Halt() error {
    return nil
}

func (p *downstreamSinkholed) Inbox(event *core.Event) error {
    // Pipe event to downstream sinkholed instance
    j, err := json.Marshal(event)

    req, err := http.NewRequest("POST", p.cfg.DestAddress, bytes.NewBuffer(j))
    req.Header.Add("Authorization", "Bearer " + p.cfg.Jwt)

    client := &http.Client{
        Timeout: time.Second * p.cfg.TimeoutSeconds,
    }
    resp, err := client.Do(req)
    if err != nil {
        log.Errorln("Failed to send event to downstream:", err)
        return nil
    }
    defer resp.Body.Close()

    if resp.StatusCode != 200 {
        log.Errorln("Failed to send event to downstream. Got http status:", resp.Status)
    }

    return nil
}

// Export the plugin
var Plugin downstreamSinkholed

