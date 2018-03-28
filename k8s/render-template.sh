#!/usr/bin/env bash
render_template() {
  eval "echo \"$(cat $1)\""
}

render_template $1
