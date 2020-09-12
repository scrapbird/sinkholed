package core

import (
    "fmt"
    "time"
    "crypto/sha256"
)

// The type used to represent a binary sample file.
type Sample struct {
    // Binary representation of the sample file
    Data []byte `json:"data"`
    // Sha256 of the Data
    Sha256 string `json:"sha256"`
    // Original file name
    FileName string `json:"filename"`
}

// Metadata is defined as an interface{} so that we can use any method for attaching 
// metadata to an event. For example, an array of string tags or a more complicated map
// of data.
type Metadata interface{}

// The type that is used to represent events passed through the sinkhole.
type Event struct {
    // This string should indicate the type of event, 'email', 'dropped file' etc.
    Type string `json:"type"`
    // A time stamp of the time the event happened
    Timestamp time.Time `json:"timestamp"`
    // An array of samples, (attachments, the file dropped etc).
    Samples []Sample `json:"samples"`
    // The source of the event, (name of the plugin that generated the event, unenforced)
    Source string `json:"source"`
    // Any metadata about the event, an array of tags or a more complicated map detailing 
    // the botnet it came from etc etc
    Metadata Metadata `json:"metadata"`
}

// Used to create a new sample representation
//
// This function will automatically calculate the sha256 sum of the sample
func NewSample(filename string, data []byte) *Sample {
    sample := Sample{
        FileName: filename,
        Data: data,
    }
    sha256sum := sha256.Sum256(data)
    sample.Sha256 = fmt.Sprintf("%x", sha256sum)
    return &sample
}

