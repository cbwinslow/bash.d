package main

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/pem"
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"os/exec"
	"time"

	"golang.org/x/crypto/ssh"
	"github.com/creack/pty"
)

func generateSigner() (ssh.Signer, error) {
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil { return nil, err }
	priv := x509.MarshalPKCS1PrivateKey(key)
	block := &pem.Block{Type: "RSA PRIVATE KEY", Bytes: priv}
	pemBytes := pem.EncodeToMemory(block)
	signer, err := ssh.ParsePrivateKey(pemBytes)
	if err != nil { return nil, err }
	return signer, nil
}

func handleConn(nConn net.Conn, config *ssh.ServerConfig) {
	defer nConn.Close()
	sshConn, chans, reqs, err := ssh.NewServerConn(nConn, config)
	if err != nil {
		log.Printf("Failed to handshake: %v", err)
		return
	}
	log.Printf("New SSH connection from %s (%s)", sshConn.RemoteAddr(), sshConn.ClientVersion())
	// Discard global requests
	go ssh.DiscardRequests(reqs)
	// Handle channels
	for newChannel := range chans {
		if newChannel.ChannelType() != "session" {
			newChannel.Reject(ssh.UnknownChannelType, "unknown channel type")
			continue
		}
		channel, requests, err := newChannel.Accept()
		if err != nil {
			log.Printf("Could not accept channel: %v", err)
			continue
		}
		// Start the TUI in a pty
		cmd := exec.Command("/bin/sh", "-c", "./term")
		ptmx, err := pty.Start(cmd)
		if err != nil {
			log.Printf("pty start error: %v", err)
			channel.Close()
			continue
		}
		// copy I/O
		go func() {
			io.Copy(channel, ptmx)
			channel.Close()
		}()
		go func() {
			io.Copy(ptmx, channel)
			ptmx.Close()
		}()
		// handle requests (like pty-req)
		go func() {
			for req := range requests {
				switch req.Type {
				case "pty-req":
					// respond OK
					req.Reply(true, nil)
				default:
					req.Reply(false, nil)
				}
			}
		}()
	}
}

func main() {
	port := flag.Int("port", 8022, "ssh listen port")
	flag.Parse()

	signer, err := generateSigner()
	if err != nil { log.Fatalf("generate signer: %v", err) }

	config := &ssh.ServerConfig{
		NoClientAuth: true,
	}
	config.AddHostKey(signer)

	ln, err := net.Listen("tcp", fmt.Sprintf("0.0.0.0:%d", *port))
	if err != nil { log.Fatalf("listen: %v", err) }
	defer ln.Close()
	log.Printf("SSH server listening on %d", *port)
	for {
		nConn, err := ln.Accept()
		if err != nil { log.Printf("accept: %v", err); continue }
		go handleConn(nConn, config)
	}
}

