package main

import (
    "flag"
    "net/http"
    "os"
    "path/filepath"

    log "github.com/sirupsen/logrus"

    "github.com/go-chi/chi"
    "github.com/go-chi/chi/middleware"
    "github.com/go-chi/render"

    "github.com/scrapbird/sinkholed/internal/api/v1"
    "github.com/scrapbird/sinkholed/internal/config"
    "github.com/scrapbird/sinkholed/pkg/plugin"
)

func Routes(cfg *config.Config, pluginManager *plugin.PluginManager, logger *log.Logger) *chi.Mux {
    var LoggerMiddleware = func(next http.Handler) http.Handler {
        formatter := middleware.DefaultLogFormatter{Logger: logger, NoColor: true}
        return middleware.RequestLogger(&formatter)(next)
    }

    router := chi.NewRouter()
    router.Use(
        render.SetContentType(render.ContentTypeJSON),
        LoggerMiddleware,
        middleware.DefaultCompress,
        middleware.RedirectSlashes,
        middleware.Recoverer,
    )

    router.Route("/api", func(r chi.Router) {
        r.Mount("/v1", v1.Routes(cfg, pluginManager))
    })

    return router
}

func main() {
    log.SetFormatter(&log.JSONFormatter{})

    // Parse command line arguments
    var configPath string
    flag.StringVar(&configPath, "config", "/etc/sinkholed/sinkholed.yml", "Config file")
    flag.Parse()

    // Initialize config
    cfg, err := config.InitConfig(configPath)
    if err != nil {
        log.Panicln("Configuration error", err)
    }

    if cfg.JwtSecret == "" {
        log.Fatalln("Please set SINKHOLED_JWTSECRET in your environment")
    }

    // Initialize logger
    lf, err := os.OpenFile(cfg.LogPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0660)
    if err != nil {
        log.Panicln("Failed to open log file:", err)
    }
    log.SetOutput(lf)

    // Set log level
    switch cfg.LogLevel {
    case "debug":
        log.SetLevel(log.DebugLevel)
    case "error":
        log.SetLevel(log.ErrorLevel)
    case "info":
    default:
        log.SetLevel(log.InfoLevel)
    }

    // Initialize plugin manager and plugins
    pluginManager := plugin.NewPluginManager(cfg)
    pluginManager.Init()

    for pluginName, pluginCfg := range cfg.PluginConfigs {
        // Inject log path and log level if they haven't already been set in plugin config
        if pluginCfg.GetString("LogPath") == "" {
            pluginCfg.Set("LogPath", cfg.LogPath)
        }
        if pluginCfg.GetString("LogLevel") == "" {
            pluginCfg.Set("LogLevel", cfg.LogLevel)
        }

        pluginManager.LoadPlugin(filepath.Join(cfg.PluginsPath, pluginName + ".so"), pluginCfg)
    }

    // Initialize router and start API server
    logger := log.New()
    logger.SetOutput(lf)
    router := Routes(cfg, pluginManager, logger)
    log.Fatal(http.ListenAndServe(cfg.ListenAddr, router))
}

