package main

import (
	"fmt"
	"io"
	"log"
	"net/http"

	"github.com/bells17/devcontainer-example/hello"
)

func handle(w http.ResponseWriter, r *http.Request) {
	_, err := io.WriteString(w, hello.Hello())
	if err != nil {
		log.Fatalf("Failed to write response: %+v", err)
	}
}

func main() {
	portNumber := "8080"
	http.HandleFunc("/", handle)
	fmt.Println("Server listening on port ", portNumber)
	err := http.ListenAndServe(":"+portNumber, nil)
	if err != nil {
		log.Fatalf("Failed serve server: %+v", err)
	}
}
