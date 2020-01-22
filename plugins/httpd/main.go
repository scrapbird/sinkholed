package main

import (
    "fmt"
    "strings"
    "io/ioutil"
    "net/http"
    "net/http/httputil"
    "time"

    log "github.com/sirupsen/logrus"

    "github.com/spf13/viper"

    "github.com/scrapbird/sinkholed/pkg/core"
    "github.com/scrapbird/sinkholed/pkg/plugin"
)

type config struct {
    Timeout int
    LogPath string
    LogLevel string
    ListenAddress string
}

type httpdPlugin struct {
    plugin.Plugin
    cfg *config
    downstream chan<- *core.Event
}

func (p *httpdPlugin) wildcardResponse(w http.ResponseWriter, req *http.Request) {
    // Note that there are some gotchas here if you require an exact request:
    // DumpRequest returns the given request in its HTTP/1.x wire representation. It should 
    // only be used by servers to debug client requests. The returned representation is an 
    // approximation only; some details of the initial request are lost while parsing it 
    // into an http.Request. In particular, the order and case of header field names are 
    // lost. The order of values in multi-valued headers is kept intact. HTTP/2 requests 
    // are dumped in HTTP/1.x form, not in their original binary representations.

    // If body is true, DumpRequest also returns the body. To do so, it consumes req.Body 
    // and then replaces it with a new io.ReadCloser that yields the same bytes. If 
    // DumpRequest returns an error, the state of req is undefined.
    rawRequest, err := httputil.DumpRequest(req, true)
    if err != nil {
        log.Errorln("Failed to get raw request", err)
    }

    body, err := ioutil.ReadAll(req.Body)
    if err != nil {
        log.Errorln("Failed to read request body", err)
    }

    metadata := map[string]interface{}{
        "SourceIp": req.RemoteAddr,
        "Raw": string(rawRequest),
        "Headers": req.Header,
        "Host": req.Host,
        "Cookies": req.Cookies(),
        "Body": string(body),
        "Method": req.Method,
    }

    event := &core.Event{
        Type: "request",
        Source: "http",
        Timestamp: time.Now(),
        Metadata: metadata,
    }

    p.downstream <- event

    fmt.Fprintln(w, "Ok")
}

func (p *httpdPlugin) httpdWorker() {
    http.HandleFunc("/", p.wildcardResponse)
    http.ListenAndServe(p.cfg.ListenAddress, nil)
}

func (p *httpdPlugin) Init(cfg *viper.Viper, downstream chan<- *core.Event) error {
    // Store properties
    p.downstream = downstream

    log.Println("Initializing httpd plugin")

    // Enable env variable overrides
    cfg.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
    cfg.SetEnvPrefix("SINKHOLED_HTTPD")
    cfg.AutomaticEnv()

    // Set default timeout
    cfg.SetDefault("Timeout", 30)

    // Workaround for viper not reading keys from env unless they are manually Get'd
    cfg.Set("Timeout", cfg.Get("Timeout"))
    cfg.Set("ListenAddress", cfg.Get("ListenAddress"))

    // Parse the config
    var c config
    cfg.Unmarshal(&c)
    p.cfg = &c

    // Start the server
    go p.httpdWorker()

    return nil
}

func (p *httpdPlugin) Halt() error {
    return nil
}

// Export the plugin
var Plugin httpdPlugin

