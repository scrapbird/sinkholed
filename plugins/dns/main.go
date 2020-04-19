package main

import (
    "fmt"
    "strings"
    "time"

    log "github.com/sirupsen/logrus"

    "github.com/miekg/dns"

    "github.com/spf13/viper"

    "github.com/scrapbird/sinkholed/pkg/core"
    "github.com/scrapbird/sinkholed/pkg/plugin"
)

type Record struct {
    Domain string
    Address string
}

type config struct {
    Timeout int
    LogPath string
    LogLevel string
    ListenAddress string
    Records []Record
}

type dnsPlugin struct {
    plugin.Plugin
    cfg *config
    downstream chan<- *core.Event
    server *dns.Server
    records map[string]string
}

func (p *dnsPlugin) parseQuery(m *dns.Msg) {
    for _, q := range m.Question {
        switch q.Qtype {
        case dns.TypeA:
            log.Infoln("Answering DNS query for", q.Name)
            ip := p.records[q.Name]

            if ip != "" {
                rr, err := dns.NewRR(fmt.Sprintf("%s A %s", q.Name, ip))
                if err == nil {
                    m.Answer = append(m.Answer, rr)
                }
            }
        }
    }
}

func (p *dnsPlugin) handleDnsRequest(w dns.ResponseWriter, r *dns.Msg) {
    m := new(dns.Msg)
    m.SetReply(r)
    m.Compress = false

    metadata := map[string]interface{}{
        "Raw": r.String(),
    }

    event := &core.Event{
        Type: "request",
        Source: "dns",
        Timestamp: time.Now(),
        Metadata: metadata,
    }

    p.downstream <- event

    switch r.Opcode {
    case dns.OpcodeQuery:
        p.parseQuery(m)
    }

    w.WriteMsg(m)
}

func (p *dnsPlugin) Init(cfg *viper.Viper, downstream chan<- *core.Event) error {
    // Store properties
    p.downstream = downstream

    log.Println("Initializing dns plugin")

    // Enable env variable overrides
    cfg.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
    cfg.SetEnvPrefix("SINKHOLED_DNS")
    cfg.AutomaticEnv()

    // Set default timeout
    cfg.SetDefault("Timeout", 30)

    // Workaround for viper not reading keys from env unless they are manually Get'd
    cfg.Set("Timeout", cfg.Get("Timeout"))
    cfg.Set("ListenAddress", cfg.Get("ListenAddress"))
    cfg.Set("Records", cfg.Get("Records"))

    // Parse the config
    var c config
    cfg.Unmarshal(&c)
    p.cfg = &c

    // This is a workaround because viper can't contain dots in config key names (domains)
    // Process records into a map
    p.records = map[string]string{}
    for _, record := range p.cfg.Records {
        p.records[record.Domain] = record.Address
    }

    // Attach request handler func
    dns.HandleFunc(".", p.handleDnsRequest)

    // Start server
    p.server = &dns.Server{
        Addr: p.cfg.ListenAddress,
        Net: "udp",
        ReadTimeout: time.Second * time.Duration(p.cfg.Timeout),
        WriteTimeout: time.Second * time.Duration(p.cfg.Timeout),
    }
    log.Infoln("Starting DNS listener on", p.cfg.ListenAddress)

    go func() {
        err := p.server.ListenAndServe()
        defer p.server.Shutdown()
        if err != nil {
            log.Fatalf("Failed to start DNS server: %s\n ", err.Error())
        }
    }()

    return nil
}

func (p *dnsPlugin) Halt() error {
    p.server.Shutdown()
    return nil
}

// Export the plugin
var Plugin dnsPlugin


