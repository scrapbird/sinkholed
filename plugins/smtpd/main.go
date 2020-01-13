package main

import (
    "time"
    "bytes"

    log "github.com/sirupsen/logrus"

    "github.com/scrapbird/go-guerrilla"
    "github.com/scrapbird/go-guerrilla/backends"
    "github.com/scrapbird/go-guerrilla/mail"

    "github.com/spf13/viper"

    "github.com/scrapbird/sinkholed/pkg/core"
    "github.com/scrapbird/sinkholed/pkg/plugin"

    "github.com/jhillyerd/enmime"
)

type config struct {
    LogPath string
    LogLevel string
    ListenAddress string
    HostMetadata map[string]map[string]interface{}
    HostTags map[string][]string
}

type smtpdPlugin struct {
    plugin.Plugin
    cfg *config
    downstream chan<- *core.Event
}

func (p *smtpdPlugin) smtpdWorker() {
    cfg := &guerrilla.AppConfig{LogFile: p.cfg.LogPath, LogLevel: p.cfg.LogLevel, AllowedHosts: []string{"."}}
    sc := guerrilla.ServerConfig{
        ListenInterface: p.cfg.ListenAddress,
        IsEnabled: true,
    }
    cfg.Servers = append(cfg.Servers, sc)
    bcfg := backends.BackendConfig{
        "save_workers_size":  3,
        "save_process":      "HeadersParser|Header|Hasher|Sinkholed",
        "primary_mail_host" : "smtp.google.com",
    }
    cfg.BackendConfig = bcfg

    d := guerrilla.Daemon{Config: cfg}

    var sinkholedProcessor = func() backends.Decorator {
        return func(processor backends.Processor) backends.Processor {
            return backends.ProcessWith(
                func(e *mail.Envelope, task backends.SelectTask) (backends.Result, error) {
                    if task == backends.TaskValidateRcpt {
                            return processor.Process(e, task)
                        } else if task == backends.TaskSaveMail {
                            // Annoying that we have to parse the MIME message again
                            // but I couldn't find an easy way using only go-guerrilla
                            envelope, err := enmime.ReadEnvelope(bytes.NewReader(e.Data.Bytes()))
                            if err != nil {
                                log.Errorln("Failed to parse envelope:", err)
                                return processor.Process(e, task)
                            }

                            samples := []core.Sample{}
                            for _, attachment := range envelope.Attachments {
                                sample := core.NewSample(attachment.FileName, attachment.Content)
                                samples = append(samples, *sample)
                            }

                            var recipients []string
                            for _, r := range e.RcptTo {
                                recipients = append(recipients, r.String())
                            }

                            metadata := map[string]interface{}{
                                "SourceIp": e.RemoteIP,
                                "MailFrom": e.MailFrom.String(),
                                "Data": e.Data.String(),
                                "Body": envelope.Text,
                                "Subject": e.Subject,
                                "RcptTo": recipients,
                            }

                            // Set host tags if set in config file
                            if tags, ok := p.cfg.HostTags[e.RemoteIP]; ok {
                                metadata["tags"] = tags
                            }

                            // Override metadata if set in config file
                            if configMetadata, ok := p.cfg.HostMetadata[e.RemoteIP]; ok {
                                log.Infoln("Found config metadata")
                                for k, v := range configMetadata {
                                    metadata[k] = v
                                }
                            }

                            event := &core.Event{
                                Type: "email",
                                Source: "smtp",
                                Timestamp: time.Now(),
                                Metadata: metadata,
                                Samples: samples,
                            }

                            p.downstream <-event
                            // call the next processor in the chain
                            return processor.Process(e, task)
                        }
                        return processor.Process(e, task)
                    },
                )
            }
        }
    d.AddProcessor("Sinkholed", sinkholedProcessor)

    log.Infoln("Starting smtp server")
    err := d.Start()

    if err != nil {
        log.Error("Failed to start SMTP server", err)
    }
}

func (p *smtpdPlugin) Init(cfg *viper.Viper, downstream chan<- *core.Event) error {
    // Store properties
    p.downstream = downstream

    log.Println("Initializing smtpd plugin")

    // Parse the config
    var c config
    cfg.Unmarshal(&c)
    p.cfg = &c
    // Workaround for https://github.com/spf13/viper/issues/324
    cfg.UnmarshalKey("HostTags", &p.cfg.HostTags)
    cfg.UnmarshalKey("HostMetadata", &p.cfg.HostMetadata)

    // Start the server
    go p.smtpdWorker()

    return nil
}

func (p *smtpdPlugin) Halt() error {
    return nil
}

// Export the plugin
var Plugin smtpdPlugin

