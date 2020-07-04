package main

import (
	"io"
	"io/ioutil"
	"log"
	"net/http"
)

var logFatal = log.Fatal
var logPrintf = log.Printf
var httpListenAndServe = http.ListenAndServe

type Person struct {
	Name string
}

func main() {
	RunServer()
}

func RunServer() {
	logPrintf("Running the server\n")
	mux := http.NewServeMux()
	mux.HandleFunc("/", RootServer)
	logFatal("ListenAndServe: ", httpListenAndServe(":8080", mux))
}

func RootServer(w http.ResponseWriter, req *http.Request) {
	addr := req.URL.Query().Get("addr")
	if len(addr) == 0 {
		w.WriteHeader(200)
		io.WriteString(w, "`addr` was not specified")
		return
	}
	logPrintf("addr: %s\n", addr)
	resp, err := http.Get(addr)
	if err != nil {
		w.WriteHeader(500)
		io.WriteString(w, "Something's terribly wrong")
		return
	}
	defer resp.Body.Close()

	logPrintf("status code: %d\n", resp.StatusCode)
	w.WriteHeader(resp.StatusCode)
	body, _ := ioutil.ReadAll(resp.Body)
	w.Write(body)
}