package main

import (
    "time"
    "sync"
    "strings"
    "encoding/json"

    log "github.com/sirupsen/logrus"

    "github.com/spf13/viper"

    "github.com/elastic/go-elasticsearch/v8"

    "github.com/scrapbird/sinkholed/pkg/core"
    "github.com/scrapbird/sinkholed/pkg/plugin"
)

const indexMapping = `{
    "mappings" : {
        "sinkholed": {
            "properties": {
                "type" : {
                    "type": "text"
                },
                "timestamp": {
                    "type": "date"
                },
                "samples": {
                    "type": "nested"
                },
                "source": {
                    "type": "text"
                },
                "metadata": {
                    "type": "object",
                    "dynamic": true
                }
            }
        }
    }
}`

type esSample struct {
    Sha256 string `json:"sha256"`
}

type esMetadata interface{}

type esEvent struct {
    Type string `json:"type"`
    Timestamp time.Time `json:"timestamp"`
    Samples []esSample `json:"samples"`
    Source string `json:"source"`
    Metadata esMetadata `json:"metadata"`
}

type config struct {
    Addresses []string
}

type esPlugin struct {
    plugin.Plugin
    cfg *config
    events chan *core.Event
    es *elasticsearch.Client
    connectMux sync.Mutex
    disconnect chan bool
}

func (p *esPlugin) Init(cfg *viper.Viper, downstream chan<- *core.Event) error {
    log.Println("Initializing elasticsearch plugin")
    p.events = make(chan *core.Event)

    // Parse the config
    var c config
    cfg.Unmarshal(&c)
    p.cfg = &c

    esConfig := elasticsearch.Config{
        Addresses: p.cfg.Addresses,
    }

    p.connectMux.Lock()
    go func() {
        defer p.connectMux.Unlock()
        // Connect to elasticsearch
        for {
            log.Println("Attempting to connect to elasticsearch")
            es, err := elasticsearch.NewClient(esConfig)
            if err == nil {
                p.es = es
                log.Println("Connected to elasticsearch")
                break
            }
            log.Errorln("Failed to connect, retrying in 5 seconds")
            time.Sleep(5 * time.Second)
        }

        var indexDate string
        var indexName string

        for {
            select {
            case event := <-p.events:
                // Check if the date has changed
                currentDate := time.Now().Format("2006-01-02")
                if indexDate != currentDate {
                    indexDate = currentDate
                    indexName = "sinkholed-" + indexDate

                    // Check if index and mappings exist - if not create them
                    resp, err := p.es.Indices.Exists([]string{indexName})
                    if err != nil {
                        log.Errorln("Error checking if index exists", err)
                    } else {
                        log.Println(resp)
                        if resp.StatusCode == 404 {
                            // Check if date has changed after the select statement unblocks
                            log.Println("Index doesn't already exist, creating...")
                            res, err := p.es.Indices.Create(indexName, p.es.Indices.Create.WithBody(strings.NewReader(indexMapping)))
                            if err != nil {
                                log.Errorln("Failed to create index", err)
                            } else {
                                log.Println("Result: ", res)
                            }
                        } else {
                            log.Println("Index already exists, res: ", resp.StatusCode)
                        }
                    }

                }

                // Mutate the event for es
                var esEvent esEvent
                for i := range event.Samples {
                    var sample esSample
                    sample.Sha256 = event.Samples[i].Sha256
                    esEvent.Samples = append(esEvent.Samples, sample)
                }
                esEvent.Type = event.Type
                esEvent.Timestamp = event.Timestamp
                esEvent.Source = event.Source
                esEvent.Metadata = event.Metadata

                body, err := json.Marshal(&esEvent)
                if err != nil {
                    log.Errorln("Error marshaling event:", event)
                    continue
                }

                _, err = p.es.Index(indexName, strings.NewReader(string(body)))
                if err != nil {
                    log.Errorln("Error indexing event:", err)
                }

            case <-p.disconnect:
                break
            }

        }
    }()
    return nil
}

func (p *esPlugin) Halt() error {
    p.disconnect <- true
    return nil
}

func (p *esPlugin) Inbox(event *core.Event) error {
    p.events <- event
    return nil
}

// Export the plugin
var Plugin esPlugin

