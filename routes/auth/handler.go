package auth

import (
	"log"
	"net/http"
)

// Handler handles Auth requests
type Handler struct {
	outlog *log.Logger
	errlog *log.Logger
}

// ServeHTTP fulfills the http.Handler contract for Handler
func (handler Handler) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	handler.outlog.Printf("Received an auth resource request!\n")
	http.Error(writer, "Not yet implemented!", http.StatusNotImplemented)
}

// NewHandler returns a new Handler
func NewHandler(outlog, errlog *log.Logger) *Handler {
	return &Handler{
		outlog: outlog,
		errlog: errlog,
	}
}
