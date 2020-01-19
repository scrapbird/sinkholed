package config

import (
    "fmt"
    "strings"

    "github.com/go-chi/jwtauth"
    "github.com/spf13/viper"
)

type Plugin struct{
    Config *viper.Viper
}

type Constants struct {
    ListenAddr  string
    JwtSecret   string
    LogPath     string
    LogLevel    string
    PluginsPath string
}

type Config struct {
    Constants

    JwtAuth *jwtauth.JWTAuth
    PluginConfigs map[string]*viper.Viper
}

func InitConfig(configPath string, onlyEnvs ...bool) (*Config, error) {
    readConfig := true

    if (len(onlyEnvs) > 0 && onlyEnvs[0]) {
        readConfig = false
    }

    v := viper.New()

    v.SetEnvPrefix("sinkholed")
    v.AutomaticEnv()

    if readConfig {
        v.SetConfigFile(configPath)

        err := v.ReadInConfig()
        if err != nil {
            return &Config{}, err
        }
    }

    viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
    v.SetEnvPrefix("sinkholed")
    v.AutomaticEnv()

    // Workaround for viper not reading kets from env unless they are manually Get'd
    for _, key := range v.AllKeys() {
        val := v.Get(key)
        v.Set(key, val)
    }
    v.Set("ListenAddr", v.Get("ListenAddr"))
    v.Set("JwtSecret", v.Get("JwtSecret"))
    v.Set("LogPath", v.Get("LogPath"))
    v.Set("LogLevel", v.Get("LogLevel"))
    v.Set("PluginsPath", v.Get("PluginsPath"))

    v.SetDefault("ListenAddr", "127.0.0.1:8080")
    v.SetDefault("LogPath", "/var/log/sinkholed.log")

    var cfg Config
    err := v.Unmarshal(&cfg.Constants)

    if readConfig {
        // Iterate over each plugin config and get a viper instance to be passed to the plugin
        cfg.PluginConfigs = make(map[string]*viper.Viper)
        rawPluginConfigs := v.Get("Plugins").(map[string]interface{})

        for pluginPath := range rawPluginConfigs {
            cfg.PluginConfigs[pluginPath] = v.Sub(fmt.Sprintf("Plugins.%s", pluginPath))
        }
    }

    cfg.JwtAuth = jwtauth.New("HS256", []byte(cfg.JwtSecret), nil)

    return &cfg, err
}
