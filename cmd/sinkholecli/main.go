package main

import (
    "fmt"
    "os"
    "flag"
    "time"
    "crypto/rand"

    "github.com/go-chi/jwtauth"

    "github.com/scrapbird/sinkholed/internal/config"
)

func printHelp() {
    fmt.Println("Usage of " + os.Args[0] + ":")
    fmt.Println(os.Args[0] + "<command> [<args>]\n")
    fmt.Printf("Subcommands:\n  gensecret\n  genjwt\n")
}

func generateRandomString(length int) (string, error) {
    const runes = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    bytes := make([]byte, length)
    _, err := rand.Read(bytes)
    if err != nil {
        return "", err
    }

    for i, b := range bytes {
        bytes[i] = runes[b%byte(len(runes))]
    }

    return string(bytes), nil
}

func gensecret(length int) int {
    secret, err := generateRandomString(length)
    if err != nil {
        fmt.Println("Failed to generate random string", err)
        return 1
    }
    fmt.Println(secret)
    return 0
}

func genjwt(configPath string, expiryDays int) int {
    // Initialize config
    cfg, err := config.InitConfig(configPath, true)
    if err != nil {
        fmt.Println("Configuration error", err)
        return 1
    }

    if cfg.JwtSecret == "" {
        fmt.Println("Please set SINKHOLED_JWT_SECRET in your environment")
        return 1
    }

    jti, err := generateRandomString(16)
    if err != nil {
        fmt.Println("Failed to generate random string for jti")
        return 1
    }

    var claims jwtauth.Claims
    if expiryDays == 0 {
        claims = jwtauth.Claims{
            "jti": jti,
        }
    } else {
        claims = jwtauth.Claims{
            "exp": time.Now().AddDate(0, 0, expiryDays).Unix(),
            "jti": jti,
        }
    }

    _, tokenString, _ := cfg.JwtAuth.Encode(claims)
    fmt.Println(tokenString)
    return 0
}

func main() {
    // // Parse command line arguments
    gensecretCommand := flag.NewFlagSet("gensecret", flag.ExitOnError)
    secretSizeFlag := gensecretCommand.Int("length", 64, "Length of the JWT secret")
    genjwtCommand := flag.NewFlagSet("genjwt", flag.ExitOnError)
    expiryTimeFlag := genjwtCommand.Int("length", 0, "Number of days until the JWT expires, 0 for never")
    configFlag := genjwtCommand.String("config", "/etc/sinkholed/sinkholed.yml", "sinkholed config file")

    if len(os.Args) < 2 {
        printHelp()
        os.Exit(1)
    }

    switch os.Args[1] {
    case "-h":
        printHelp()
        os.Exit(0)
    case "gensecret":
        gensecretCommand.Parse(os.Args[2:])
        os.Exit(gensecret(*secretSizeFlag))
    case "genjwt":
        genjwtCommand.Parse(os.Args[2:])
        os.Exit(genjwt(*configFlag, *expiryTimeFlag))
    default:
        printHelp()
        os.Exit(2)
    }
}
