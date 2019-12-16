package main

import (
    "os"
    "io/ioutil"
    "path/filepath"

    "github.com/spf13/viper"

    log "github.com/sirupsen/logrus"

    "github.com/scrapbird/sinkholed/pkg/core"
    "github.com/scrapbird/sinkholed/pkg/plugin"
)

type config struct {
    DestDir string
}

type sampleFs struct {
    plugin.Plugin
    cfg *config
    x int
}

func (p *sampleFs) Init(cfg *viper.Viper, downstream chan<- *core.Event) error {
    log.Println("Initializing sampleFs plugin")

    // Parse the config
    var c config
    cfg.Unmarshal(&c)
    p.cfg = &c

    return nil
}

func (p *sampleFs) Halt() error {
    return nil
}


func (p *sampleFs) Inbox(event *core.Event) error {
    for _, sample := range event.Samples {
        filePath := filepath.Join(p.cfg.DestDir, sample.Sha256)

        if _, err := os.Stat(filePath); os.IsNotExist(err) {
            err := ioutil.WriteFile(filePath, sample.Data, 0644)
            if err != nil {
                log.Errorln("Failed to write file", filePath)
            } else {
                log.Println("Wrote file", filePath)
            }
        }

    }
    return nil
}

// Export the plugin
var Plugin sampleFs

