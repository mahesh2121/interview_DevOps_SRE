#!/bin/bash
STAGE=dev
NAMESPACE=dev
RELEASE=webserver
LOCATION=stages/$STAGE/values.yaml
helm upgrade --install -n $NAMESPACE $RELEASE --create-namespace -f $LOCATION .