package v1

import (
    "fmt"
    "net/http"
    "encoding/json"
    "encoding/base64"
    "crypto/sha256"

    "github.com/go-chi/chi"
    "github.com/go-chi/render"
    "github.com/go-chi/jwtauth"

    // log "github.com/sirupsen/logrus"

    "github.com/scrapbird/sinkholed/internal/config"
    "github.com/scrapbird/sinkholed/pkg/plugin"
    "github.com/scrapbird/sinkholed/pkg/core"
)

type APIResponse struct {
    Message string `json:"message"`
}

func Routes(cfg *config.Config, pluginManager *plugin.PluginManager) *chi.Mux {
    router := chi.NewRouter()

    // Public routes
    router.Group(func (r chi.Router) {
        r.Get("/", Healthcheck)
    })

    // Private routes
    router.Group(func (r chi.Router) {
        r.Use(jwtauth.Verifier(cfg.JwtAuth))
        r.Use(jwtauth.Authenticator)
        r.Post("/event", PostEvent(cfg, pluginManager))
    })

    return router
}

func Healthcheck(w http.ResponseWriter, r *http.Request) {
    resp := APIResponse{
        Message: "ok",
    }
    render.JSON(w, r, resp)
}

func PostEvent(cfg *config.Config, pluginManager *plugin.PluginManager) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        if r.Body == nil {
            http.Error(w, "Please send a request body", 400)
            return
        }

        var event core.Event

        err := json.NewDecoder(r.Body).Decode(&event)
        if err != nil {
            http.Error(w, err.Error(), 400)
            return
        }

        for i := range event.Samples {
            // Decode sample and calculate hash
            _, err = base64.StdEncoding.Decode(event.Samples[i].Data, event.Samples[i].Data)
            sha256sum := sha256.Sum256(event.Samples[i].Data)
            event.Samples[i].Sha256 = fmt.Sprintf("%x", sha256sum)
        }

        pluginManager.EmitEvent(&event)

        resp := APIResponse{
            Message: "ok",
        }
        render.JSON(w, r, resp)
    }
}

