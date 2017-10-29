#!/bin/sh

sudo protoc --descriptor_set_out pbhead.pb pbhead.proto
sudo protoc --descriptor_set_out Person.pb Person.proto
