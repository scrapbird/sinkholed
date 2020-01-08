package config

import (
    "fmt"

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

    if readConfig {
        viper.SetConfigFile(configPath)

        err := viper.ReadInConfig()
        if err != nil {
            return &Config{}, err
        }
    }

    viper.SetDefault("ListenAddr", "127.0.0.1:8080")
    viper.SetDefault("LogPath", "/var/log/sinkholed.log")

    viper.BindEnv("JwtSecret", "SINKHOLED_JWT_SECRET")

    var cfg Config
    err := viper.Unmarshal(&cfg.Constants)

    if readConfig {
        // Iterate over each plugin config and get a viper instance to be passed to the plugin
        cfg.PluginConfigs = make(map[string]*viper.Viper)
        rawPluginConfigs := viper.Get("Plugins").(map[string]interface{})

        for pluginPath := range rawPluginConfigs {
            cfg.PluginConfigs[pluginPath] = viper.Sub(fmt.Sprintf("Plugins.%s", pluginPath))
        }
    }

    cfg.JwtAuth = jwtauth.New("HS256", []byte(cfg.JwtSecret), nil)

    return &cfg, err
}
