//go:build wish
// +build wish

package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/signal"
	"path/filepath"
	"strings"
	"syscall"
	"os/user"

	"github.com/charmbracelet/wish"
	"github.com/charmbracelet/wish/logging"
	wishtea "github.com/charmbracelet/wish/tea"
	"github.com/charmbracelet/wish/middleware"
	"golang.org/x/crypto/ssh"
)

// allowlist entry
type allowEntry struct {
	User       string   `json:"user"`
	PubKey     string   `json:"pubkey"`
	AllowedExec []string `json:"allowed_exec,omitempty"`
	IsAdmin    bool     `json:"is_admin,omitempty"`
}

func loadAllowlist(path string) ([]allowEntry, error) {
	if path == "" {
		return nil, nil
	}
	b, err := ioutil.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var arr []allowEntry
	if err := json.Unmarshal(b, &arr); err != nil {
		return nil, err
	}
	return arr, nil
}

func allowedExecForUser(user string, allowed []allowEntry) []string {
	for _, a := range allowed {
		if a.User == user {
			return a.AllowedExec
		}
	}
	return nil
}

func isAdminForUser(user string, allowed []allowEntry) bool {
	for _, a := range allowed {
		if a.User == user {
			return a.IsAdmin
		}
	}
	return false
}

func main() {
	port := flag.Int("port", 8022, "ssh listen port")
	hostKey := flag.String("host-key", "", "path to host private key (recommended)")
	allowPath := flag.String("allowlist", "", "path to allowlist JSON file")
	flag.Parse()

	allowed, err := loadAllowlist(*allowPath)
	if err != nil {
		log.Fatalf("failed to load allowlist: %v", err)
	}

	// build options
	opts := []wish.Option{
		wish.WithAddress(fmt.Sprintf(":%d", *port)),
		wish.WithMiddleware(
			logging.Middleware(),
			middleware.PublicKeyAuth(func(conn ssh.ConnMetadata, key ssh.PublicKey) bool {
				// match key against allowlist entries
				for _, a := range allowed {
					if a.User == conn.User() {
						// compare key string
						if strings.TrimSpace(a.PubKey) == strings.TrimSpace(string(ssh.MarshalAuthorizedKey(key))) {
							return true
						}
					}
				}
				return false
			}),
			// middleware to set allowed execs and admin flag into the session environment
			middleware.Env(func(conn ssh.ConnMetadata, key ssh.PublicKey) map[string]string {
				allowedExec := allowedExecForUser(conn.User(), allowed)
				isAdmin := isAdminForUser(conn.User(), allowed)
				env := map[string]string{}
				if len(allowedExec) > 0 {
					env["SSH_ALLOWED_EXEC"] = strings.Join(allowedExec, ",")
				}
				if isAdmin {
					env["SSH_IS_ADMIN"] = "1"
				} else {
					env["SSH_IS_ADMIN"] = "0"
				}
				// expose the authenticated username to session
				env["SSH_USER"] = conn.User()
				// resolve user's home directory more robustly
				homePath := ""
				if u, err := user.Lookup(conn.User()); err == nil {
					homePath = u.HomeDir
				} else {
					// fallback
					if conn.User() == "root" {
						homePath = "/root"
					} else {
						homePath = filepath.Join("/home", conn.User())
					}
				}
				pluginEnvPath := filepath.Join(homePath, ".bash_functions.d", "plugins", "enabled_env.sh")
				env["SSH_PLUGIN_ENV"] = pluginEnvPath
				return env
			}),
		),
	}

	if *hostKey != "" {
		opts = append(opts, wish.WithHostKeyPath(*hostKey))
	}

	// Run the TUI in-process for each session via wish/tea
	opts = append(opts, wish.WithHandler(wishtea.NewHandler(initialModel)))

	srv, err := wish.NewServer(opts...)
	if err != nil {
		log.Fatalf("failed to create wish server: %v", err)
	}

	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()

	go func() {
		<-ctx.Done()
		log.Printf("shutting down...")
		srv.Close()
	}()

	log.Printf("wish server listening on :%d", *port)
	if err := srv.ListenAndServe(); err != nil {
		log.Fatalf("server error: %v", err)
	}
}
