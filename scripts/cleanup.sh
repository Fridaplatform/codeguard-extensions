#!/bin/bash

echo "Cleaning up SonarQube container..."

docker rm -f sonar-ephemeral || true

echo "Cleanup finished"